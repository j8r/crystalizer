module Crystalizer::YAML
  def self.serializer(io : IO, & : Serializer ->) : Nil
    Serializer.new(io) do |serializer|
      yield serializer
    end
  end

  def self.serialize(object) : String
    String.build do |str|
      serialize str, object
    end
  end

  def self.serialize(io : IO, object : O) : Nil forall O
    Serializer.new io, &.serialize object
  end

  struct Serializer
    include Crystalizer::Serializer

    def initialize(@builder : ::YAML::Nodes::Builder)
    end

    def self.new(io : IO, & : Serializer ->) : Nil
      nodes_builder = ::YAML::Nodes::Builder.new
      yield new nodes_builder
      ::YAML.build(io) do |builder|
        nodes_builder.document.to_yaml builder
      end
    end

    private def de_unionize(object : U) forall U
      {% for u in U.union_types %}
        return serialize object if object.is_a? {{u}}
      {% end %}
    end

    def serialize(object : O) : Nil forall O
      @builder.mapping do
        Crystalizer.each_ivar(object) do |key, value|
          de_unionize key
          de_unionize value
        end
      end
    end

    def serialize(any : Crystalizer::Any)
      serialize any.raw
    end

    def serialize(object : ::YAML::Serializable)
      object.to_yaml @builder
    end

    def serialize(hash : Hash)
      @builder.mapping(reference: hash) do
        hash.each do |key, value|
          serialize key
          serialize value
        end
      end
    end

    def serialize(array : Array | Deque | Set | Tuple)
      @builder.sequence(reference: (array.is_a?(Array) ? array : nil)) do
        array.each do |value|
          serialize value
        end
      end
    end

    def serialize(named_tuple : NamedTuple)
      @builder.mapping do
        named_tuple.each do |key, value|
          serialize key
          serialize value
        end
      end
    end

    def serialize(bool : Bool)
      @builder.scalar bool
    end

    def serialize(object : Enum)
      @builder.scalar object.value
    end

    def serialize(null : Nil)
      @builder.scalar ""
    end

    def serialize(object : Number | Path | String | Symbol)
      @builder.scalar object.to_s
    end

    def serialize(slice : Slice(UInt8))
      @builder.scalar Base64.encode(slice), tag: "tag:yaml.org,2002:binary"
    end

    def serialize(time : Time)
      @builder.scalar Time::Format::YAML_DATE.format(time)
    end
  end
end
