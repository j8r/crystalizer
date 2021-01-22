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

  # Serializes a `String` to bytes, written to the `io`, and add a trailing `byte_delimiter`.
  def serialize(string : Path | String | Symbol)
    string.to_s @io
    if byte_delimiter = @byte_delimiter
      @io.write_byte byte_delimiter
    end
  end

  def serialize(object : O) forall O
    {% for ivar in O.instance_vars %}
    {% ann = ivar.annotation(::Crystalizer::Field) %}
      {% unless ann && ann[:ignore] %}
        {% key = ((ann && ann[:key]) || ivar).id.stringify %}
        serialize object.@{{ivar}}
      {% end %}
    {% end %}
  end
end
