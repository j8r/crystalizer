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
  def serialize(string : Path | String | Symbol)
    string.to_s @io
    if string_delimiter = @string_delimiter
      @io << string_delimiter
    end
  end

  def serialize(string : String, max_size : Int)
    if string.size < max_size
      serialize string
    else
      raise Error.new "String too long (max size: #{max_size})"
    end
  end

  private def de_unionize(object : U) forall U
    {% for u in U.union_types %}
      return serialize object if object.is_a? {{u}}
    {% end %}
  end

  def serialize(object : O) forall O
    Crystalizer.each_ivar(object) do |_, value|
      de_unionize value
    end
  end
end
