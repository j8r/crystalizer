module Crystalizer::YAML
  def serialize(object)
    String.build do |str|
      serialize str, object
    end
  end

  def serialize(io : IO, object : O) forall O
    nodes_builder = ::YAML::Nodes::Builder.new
    serialize nodes_builder, object
    ::YAML.build(io) do |builder|
      nodes_builder.document.to_yaml builder
    end
  end

  def serialize(builder : ::YAML::Nodes::Builder, object : O) forall O
    builder.mapping do
      Crystalizer.each_ivar(object) do |key, value|
        serialize builder, key
        serialize builder, value
      end
    end
  end

  def serialize(
    builder : ::YAML::Nodes::Builder,
    object : ::YAML::Serializable | Array | Bool | Enum | Float | Hash | Int | NamedTuple | Nil | Set | String | Symbol | Time | Tuple
  )
    object.to_yaml builder
  end
end
