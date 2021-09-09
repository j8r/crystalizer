module Crystalizer::JSON
  def self.deserialize(string_or_io : IO | String, to type : T.class) : T forall T
    Deserializer.new(string_or_io).deserialize to: type
  end

  # Parses a JSON document as a JSON::Any.
  def self.parse(string_or_io : String | IO) : Any
    deserialize string_or_io, Any
  end

  struct Deserializer
    include Crystalizer::Deserializer

    def initialize(@pull : ::JSON::PullParser)
    end

    def self.new(string_or_io : IO | String) : Deserializer
      new ::JSON::PullParser.new(string_or_io)
    end

    def deserialize(to type : ::JSON::Serializable.class | Any.class)
      type.new @pull
    end

    private def de_unionize(object : U) forall U
      {% for type in U.union_types %}
        return deserialize object if object.is_a? {{type}}
      {% end %}
    end

    def deserialize(to type : Hash.class)
      hash = type.new
      key_class, value_class = typeof(hash.first)

      @pull.read_object do |key, key_location|
        if parsed_key = self.class.deserialize_object_key? key, key_class
          hash[parsed_key] = deserialize value_class
        else
          raise ::JSON::ParseException.new("Can't convert #{key.inspect} into #{key_class}", *key_location)
        end
      end

      hash
    end

    def deserialize(to type : Array.class | Deque.class | Set.class) forall T
      array = type.new
      value_class = typeof(array.first)
      @pull.read_array do
        array << deserialize value_class
      end
      array
    end

    def deserialize(to type : Tuple.class)
      @pull.read_begin_array
      tuple = Crystalizer.create_tuple type do |value_type|
        deserialize value_type
      end
      @pull.read_end_array
      tuple
    end

    def deserialize(to type : NamedTuple.class)
      deserializer = Crystalizer::Deserializer::NamedTupleObject.new type

      @pull.read_object do |key|
        deserializer.set_value key do |value_type|
          de_unionize value_type
        end
      end

      deserializer.named_tuple
    end

    def deserialize(to type : Enum.class)
      deserialize_enum type
    end

    private def deserialize_enum(to type : E.class) forall E
      {% if E.annotation(Flags) %}
        value = {{ E }}::None
        @pull.read_array do
          value |= type.parse?(@pull.read_string) || @pull.raise "Unknown enum #{type} value: #{@pull.string_value.inspect}"
        end
        value
      {% else %}
        type.parse?(@pull.read_string) || @pull.raise "Unknown enum #{type} value: #{@pull.string_value.inspect}"
      {% end %}
    end

    def deserialize(to type : Bool.class)
      @pull.read_bool
    end

    def deserialize(to type : Nil.class)
      @pull.read_null
    end

    def deserialize(to type : Path.class)
      Path.new @pull.read_string
    end

    def deserialize(to type : String.class)
      @pull.read_string
    end

    def deserialize(to type : Float.class)
      type.new case @pull.kind
      when .int?
        value = @pull.int_value
        @pull.read_next
        value
      else
        @pull.read_float
      end
    end

    def deserialize(to type : Int.class)
      location = @pull.location
      value = @pull.read_int
      begin
        type.new value
      rescue ex : OverflowError
        raise ::JSON::ParseException.new("Can't read #{type}", *location, ex)
      end
    end

    def deserialize(to type : Time.class)
      Time::Format::ISO_8601_DATE_TIME.parse(@pull.read_string)
    end

    def self.deserialize_object_key?(number : String, to type : Number::Primitive.class)
      number.new number
      # Waiting to have .new?
    rescue
      nil
    end

    def self.deserialize_object_key?(string : String, to type : String.class)
      string
    end

    private def deserialize_union(type : T.class) forall T
      location = @pull.location

      {% begin %}
        case @pull.kind
        {% if T.union_types.includes? Nil %}
        when .null?
          return @pull.read_null
        {% end %}
        {% if T.union_types.includes? Bool %}
        when .bool?
          return @pull.read_bool
        {% end %}
        {% if T.union_types.includes? String %}
        when .string?
          return @pull.read_string
        {% end %}
        when .int?
        {% type_order = [Int64, UInt64, Int32, UInt32, Int16, UInt16, Int8, UInt8, Float64, Float32] %}
        {% for type in type_order.select { |t| T.union_types.includes? t } %}
          value = @pull.read?({{type}})
          return value unless value.nil?
        {% end %}
        when .float?
        {% type_order = [Float64, Float32] %}
        {% for type in type_order.select { |t| T.union_types.includes? t } %}
          value = @pull.read?({{type}})
          return value unless value.nil?
        {% end %}
        else
          # no priority type
        end
      {% end %}

      {% begin %}
        {% primitive_types = [Nil, Bool, String] + Number::Primitive.union_types %}
        {% non_primitives = T.union_types.reject { |t| primitive_types.includes? t } %}

        # If after traversing all the types we are left with just one
        # non-primitive type, we can parse it directly (no need to use `read_raw`)
        {% if non_primitives.size == 1 %}
          return deserialize {{non_primitives[0]}}
        {% else %}
          string = @pull.read_raw
          {% for type in non_primitives %}
            begin
              return deserialize string, {{type}}
            rescue ::JSON::ParseException
              # Ignore
            end
          {% end %}
          raise ::JSON::ParseException.new("Couldn't parse #{type} from #{string}", *location)
        {% end %}
      {% end %}
    end

    def deserialize(to type : T.class) : T forall T
      {% if T.union_types.size > 1 %}
        deserialize_union type
      {% elsif T < Array || T < Deque || T < Set || T < Hash %}
        deserialize type
      {% else %}
        deserializer = Crystalizer::Deserializer::SelfDescribingObject.new type
        @pull.read_begin_object
        while !@pull.kind.end_object?
          key = @pull.read_object_key
          deserializer.set_ivar key do |variable|
            if variable.nilable || variable.has_default
              @pull.read_null_or do
                de_unionize variable.type
              end
            else
              de_unionize variable.type
            end
          end
        end
        deserializer.object_instance
      {% end %}
    end
  end
end
