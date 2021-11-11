module Crystalizer::JSON
  def self.serialize(io : IO, object, *, indent : String = Serializer.indent) : Nil
    Serializer.new io do |serializer|
      serializer.indent = indent
      serializer.serialize object
    end
  end

  def self.serialize(object, *, indent : String = Serializer.indent) : String
    String.build do |str|
      serialize str, object, indent: indent
    end
  end

  struct Serializer
    include Crystalizer::Serializer

    class_property indent : String = "  "

    def initialize(@builder : ::JSON::Builder)
    end

    def self.new(io : IO, & : Serializer ->) : Nil
      ::JSON.build(io) do |builder|
        yield Serializer.new builder
      end
    end

    def indent=(value : String)
      @builder.indent = value
    end

    private def de_unionize(object : U) forall U
      {% for type in U.union_types %}
        return serialize object if object.is_a? {{type}}
      {% end %}
    end

    def serialize(object : O) : Nil forall O
      @builder.object do
        Crystalizer.each_ivar(object) do |key, value|
          @builder.field key do
            de_unionize value
          end
        end
      end
    end

    def serialize(any : Crystalizer::Any)
      serialize any.raw
    end

    def serialize(object : ::JSON::Serializable)
      object.to_json builder
    end

    def serialize(hash : Hash)
      @builder.object do
        hash.each do |key, value|
          @builder.field self.class.serialize_object_key(key) do
            serialize value
          end
        end
      end
    end

    def serialize(array : Array | Deque | Set | Tuple)
      @builder.array do
        array.each do |value|
          serialize value
        end
      end
    end

    def serialize(named_tuple : NamedTuple)
      @builder.object do
        named_tuple.each do |key, value|
          @builder.field key do
            serialize value
          end
        end
      end
    end

    def serialize(bool : Bool)
      @builder.bool bool
    end

    def serialize(object : Enum)
      serialize_enum object
    end

    private def serialize_enum(object : E) forall E
      {% if E.annotation(Flags) %}
        @builder.array do
          object.each do |member, _value|
            @builder.string(member.to_s.underscore)
          end
        end
      {% else %}
        @builder.string(object.to_s.underscore)
      {% end %}
    end

    def serialize(null : Nil)
      @builder.null
    end

    def serialize(number : Number::Primitive)
      @builder.number number
    end

    def serialize(object : Path | String | Symbol)
      @builder.string object.to_s
    end

    def serialize(time : Time)
      @builder.string(Time::Format::RFC_3339.format(time, fraction_digits: 0))
    end

    def self.serialize_object_key(null : Nil)
      ""
    end

    def self.serialize_object_key(any : Crystalizer::Any)
      serialize_object_key any.to Path | String | Symbol | Number::Primitive
    end

    def self.serialize_object_key(object : Path | String | Symbol | Number::Primitive)
      object.to_s
    end
  end
end
