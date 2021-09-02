struct Crystalizer::ByteFormat
  def self.serialize(object) : Bytes
    io = IO::Memory.new
    new(io).serialize object
    io.to_slice
  end

  def self.serialize(io : IO, object) : Nil
    new(io).serialize object
  end

  def serialize(number : Number::Primitive)
    @io.write_bytes number, @format
  end

  def serialize(bool : Bool)
    @io.write_byte (bool ? 1_u8 : 0_u8)
  end

  def serialize(bytes : Bytes)
    @io.write bytes, @format
  end

  def serialize(object : Enum)
    @io.write_bytes object.value, @format
  end

  def serialize(object : NamedTuple | Hash)
    object.each do |key, value|
      serialize key
      serialize value
    end
  end

  def serialize(array : Array | Deque | Set | Tuple)
    array.each do |value|
      serialize value
    end
  end

  # Serializes a `String` to bytes, written to the `io`, and add a trailing `string_delimiter`.
  def serialize(string : Path | String | Symbol, add_delimiter : Bool = true)
    string.to_s @io
    if add_delimiter && (string_delimiter = @string_delimiter)
      @io << string_delimiter
    end
  end

  def serialize(string : String, size : Int)
    if string.bytesize != size
      raise Error.new "String size not expected, expected: #{size}, have: #{string.bytesize}"
    end
    serialize string, add_delimiter: false
  end

  def serialize(string : String, size : Range(Int32?, Int32?))
    unless size.includes? string.bytesize
      raise Error.new "String size not in range: #{size} (have: #{string.bytesize})"
    end
    serialize string, add_delimiter: true
  end

  private def de_unionize(object : U, variable : Variable) forall U
    {% for u in U.union_types %}
      if object.is_a? {{u}}
        return case variable_type = variable.type
        when String.class
          if size = variable.annotations.try &.[:size]
            serialize object, size: size
          else
            serialize object
          end
        else
          serialize object
        end
      end
    {% end %}
  end

  def serialize(object : O) forall O
    Crystalizer.each_ivar(object) do |_, value, var|
      de_unionize value, var
    end
  end
end
