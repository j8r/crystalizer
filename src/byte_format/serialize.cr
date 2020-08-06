struct Crystalizer::ByteFormat
  def self.serialize(to object) : Bytes
    io = IO::Memory.new
    new(io).serialize object
    io.to_slice
  end

  def self.serialize(io : IO, to object) : Nil
    serialize io, object
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

  # Serializes a `String` to bytes, written to the `io`, and add a trailing `byte_delimiter`.
  def serialize(string : Path | String | Symbol)
    string.to_s @io
    if byte_delimiter = @byte_delimiter
      @io.write_byte byte_delimiter
    end
  end

  def serialize(object : O) forall O
    Crystalizer.each_ivar(object) do |_, value|
      serialize value
    end
  end
end
