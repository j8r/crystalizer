module Crystalizer::JSON
  def self.serialize(object, *, indent : String = "  ") : String
    String.build do |str|
      serialize str, object, indent
    end
  end

  def self.serialize(io : IO, object, indent : String = "  ")
    ::JSON.build(io, indent) do |builder|
      serialize builder, object
    end
  end

  def self.serialize(builder : ::JSON::Builder, object : O) forall O
    builder.object do
      Crystalizer.each_ivar(object) do |key, value|
        builder.field key do
          de_unionize(builder, value)
        end
      end
    end
  end

  def self.serialize(builder : ::JSON::Builder, any : Crystalizer::Any)
    serialize builder, any.raw
  end

  def self.serialize_object_key(any : Crystalizer::Any)
    serialize_object_key any.to Path | String | Symbol | Number::Primitive
  end

  def self.serialize(builder : ::JSON::Builder, object : ::JSON::Serializable)
    object.to_json builder
  end

  def self.serialize(builder : ::JSON::Builder, hash : Hash)
    builder.object do
      hash.each do |key, value|
        builder.field serialize_object_key(key) do
          serialize builder, value
        end
      end
    end
  end

  def self.serialize(builder : ::JSON::Builder, array : Array | Deque | Set | Tuple)
    builder.array do
      array.each do |value|
        serialize builder, value
      end
    end
  end

  def self.serialize(builder : ::JSON::Builder, named_tuple : NamedTuple)
    builder.object do
      named_tuple.each do |key, value|
        builder.field key do
          serialize builder, value
        end
      end
    end
  end

  def self.serialize(builder : ::JSON::Builder, bool : Bool)
    builder.bool bool
  end

  def self.serialize(builder : ::JSON::Builder, object : Enum)
    builder.number object.value
  end

  def self.serialize(builder : ::JSON::Builder, null : Nil)
    builder.null
  end

  def self.serialize_object_key(null : Nil)
    ""
  end

  def self.serialize(builder : ::JSON::Builder, number : Number::Primitive)
    builder.number number
  end

  def self.serialize_object_key(object : Path | String | Symbol | Number::Primitive)
    object.to_s
  end

  def self.serialize(builder : ::JSON::Builder, object : Path | String | Symbol)
    builder.string object.to_s
  end

  def self.serialize(builder : ::JSON::Builder, time : Time)
    builder.string(Time::Format::RFC_3339.format(time, fraction_digits: 0))
  end

  private def self.de_unionize(builder, object : U) forall U
    {% for u in U.union_types %}
      if object.is_a? {{u}}
        return serialize builder, object
      end
    {% end %}
  end
end
