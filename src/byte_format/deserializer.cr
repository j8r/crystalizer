struct Crystalizer::ByteFormat
  include Crystalizer::Deserializer

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
    deserializer = Deserializer::NamedTupleObject.new type

    deserializer.size.times do
      str = deserialize String
      deserializer.set_value str do |value_type|
        deserialize value_type
      end
    end
    deserializer.named_tuple
  end

  def deserialize(to type : Number::Primitive.class)
    @io.read_bytes type, @format
  end

  def deserialize(to type : Path.class)
    Path.new deserialize(String, bytesize)
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
  def deserialize(to type : String.class, bytesize : Range(Int32?, Int32?))
    string = if max_bytesize = bytesize.end
               # An alternative to reading limit `max_bytesize + 1` would be to read `max_bytesize` or
               # `max_bytesize - 1` (depending on `size.excludes_end?`), then peek the next char for
               # `@string_delimiter`, and then consume it (if it is a valid delimiter) or set a flag
               # for string being out of bounds.
               @io.gets(@string_delimiter.as(Char), max_bytesize + 1, true) || ""
             else
               deserialize type
             end

    unless bytesize.includes? string.bytesize
      raise Error.new "String bytesize not in range: #{bytesize}"
    end

    string
  end

  # Deserializes a `String` from reading from the `io`. String is exactly `bytesize` bytes with no trailing `@string_delimiter`.
  def deserialize(to type : String.class, bytesize : Int)
    @io.read_string bytesize
  end

  def deserialize(to type : Tuple.class)
    Crystalizer.create_tuple type do |value_type|
      deserialize value_type
    end
  end

  private def de_unionize(object : U) forall U
    {% for type in U.union_types %}
      return deserialize object if object.is_a? {{type}}
    {% end %}
  end

  def deserialize(to type : T.class) : T forall T
    {% if T.union_types.size > 1 %}
      {% raise "Crystalizer::ByteFormat does not support unions; the protocol requires unambiguous field types." %}
    {% elsif T < Array || T < Deque || T < Set || T < Hash %}
      deserialize type
    {% else %}
      deserializer = Deserializer::NonSelfDescribingObject.new type
      deserializer.set_each_ivar do |variable|
        if (variable_type = variable.type).is_a?(String.class) && (bytesize = variable.annotations.try &.[:bytesize])
          deserialize String, bytesize: bytesize
        else
          de_unionize variable.type
        end
      end
      deserializer.object_instance
    {% end %}
  end
end
