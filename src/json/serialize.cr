module Crystalizer::JSON
  def serialize(object, *, indent : String = "  ")
    String.build do |str|
      serialize str, object, indent
    end
  end

  def serialize(io : IO, object, indent : String = "  ")
    ::JSON.build(io, indent) do |builder|
      serialize builder, object
    end
  end

  def serialize(builder : ::JSON::Builder, object : O) forall O
    builder.object do
      Crystalizer.each_ivar(object) do |key, value|
        builder.field key do
          serialize builder, value
        end
      end
    end
  end

  def serialize(
    builder : ::JSON::Builder,
    object : ::JSON::Serializable | Bool | Enum | Float | Int | NamedTuple | Nil | String | Symbol | Time
  )
    object.to_json builder
  end

  def serialize(builder : ::JSON::Builder, hash : Hash)
    builder.object do
      hash.each do |key, value|
        builder.field key.to_json_object_key do
          serialize builder, value
        end
      end
    end
  end

  def serialize(builder : ::JSON::Builder, array : Array | Deque | Set | Tuple)
    builder.array do
      array.each do |value|
        serialize builder, value
      end
    end
  end
end
