struct Crystalizer::ByteFormat
  def self.deserialize(bytes : Bytes, to type : T.class) : T forall T
    new(IO::Memory.new(bytes)).deserialize to: type
  end

  def self.deserialize(io : IO, to type : T.class) : T forall T
    new(io).deserialize to: type
  end

  private def yield_until_empty(type, &)
    if !(io_memory = @io).is_a? IO::Memory
      raise Error.new "Deserializing to a #{type} requires an IO::Memory, not `#{@io.class}`."
    end
    while io_memory.pos < io_memory.bytesize
      yield
    end
  end

  # Requires the `@io` to be an `IO::Memory`.
  def deserialize(to type : Array.class | Deque.class | Set.class)
    array = type.new
    value_class = typeof(array.first)
    yield_until_empty type do
      array << deserialize value_class
    end
    array
  end

  def deserialize(to type : Bool.class)
    case byte = @io.read_byte
    when 0_u8 then false
    when 1_u8 then true
    else           raise Error.new "Invalid boolean byte different from 0 or 1: #{byte}"
    end
  end

  def deserialize(to type : Bytes.class)
    @io.gets_to_end.to_slice
  end

  def deserialize(to type : Enum.class)
    type.from_value deserialize(typeof(type.values.first.value))
  end

  def deserialize(to type : Hash.class)
    hash = type.new
    key_class, value_class = typeof(hash.first)

    yield_until_empty type do
      key = deserialize key_class
      value = deserialize value_class
      hash[key] = value
    end
    hash
  end

  def deserialize(to type : NamedTuple.class)
    deserializer = Deserializer::NamedTuple.new type

    deserializer.size.times do
      str = deserialize String
      deserializer.set_value str do |value_type|
        deserialize value_type
      end
    end
    deserializer.named_tuple
  end

  def deserialize(to type : Number::Primitive.class)
    begin
      @io.read_bytes type, @format
    rescue e
      raise Error.new e.message
    end
  end

  def deserialize(to type : Path.class)
    Path.new deserialize(String, size)
  end

  # Deserializes a `String` from reading from the `io`, delimited by a trailing `string_delimiter`.
  def deserialize(to type : String.class)
    if string_delimiter = @string_delimiter
      @io.gets(string_delimiter, true) || ""
    else
      @io.gets_to_end
    end
  end

  # :ditto:
  def deserialize(to type : String.class, size : Range)
    str = if max_size = size.end
      # An alternative to reading limit `max_size + 1` would be to read `max_size` or `max_size - 1`
      # (depending on `size.excludes_end?`), then peek the next char for '\0' and either consume it
      # (if it is '\0') or set a flag for string being out of bounds.
      @io.gets(@string_delimiter.not_nil!, max_size + 1, true) || ""
    else
      deserialize type
    end

    if max_size && ((excludes_end = size.excludes_end?) ? str.size >= max_size : str.size > max_size)
      raise Error.new "String size not in range: #{size}"
    end

    if (min_size = size.begin) && str.size < min_size
      raise Error.new "String size not in range: #{size}"
    end

    str
  end

  # Deserializes a `String` from reading from the `io`. String is exactly `size` bytes with no trailing '\0'.
  def deserialize(to type : String.class, size : Int)
    @io.read_string size
  end

  def deserialize(to type : Tuple.class)
    Crystalizer.create_tuple type do |value_type|
      deserialize value_type
    end
  end

  def deserialize(to type : T.class) : T forall T
    {% if T.union_types.size > 1 %}
      {% raise "Crystalizer::ByteFormat does not support unions; the protocol requires unambiguous field types." %}
    {% else %}
      deserializer = Deserializer::NonSelfDescribingObject.new type
      deserializer.set_each_ivar do |variable|
        case variable_type = variable.type
        when String.class
          if size = variable.annotations.try &.[:size]
            deserialize variable_type, size: size
          else
            deserialize variable_type
          end
        else
          deserialize variable_type
        end
      end
      deserializer.object_instance
    {% end %}
  end
end
