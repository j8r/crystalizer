module Crystalizer::YAML
  def self.deserialize(string_or_io : String | IO, to type : T.class) : T forall T
    Deserializer.new(string_or_io).deserialize to: type
  end

  # Deserializes a YAML document according to the core schema.
  def self.parse(string_or_io : String | IO) : Any
    deserialize string_or_io, Any
  end

  struct Deserializer
    include Crystalizer::Deserializer

    def initialize(@context : ::YAML::ParseContext, @node : ::YAML::Nodes::Node)
    end

    def self.new(string_or_io : String | IO) : Deserializer
      document = ::YAML::Nodes.parse(string_or_io)

      # If the document is empty we simulate an empty scalar with
      # plain style, that parses to Nil
      node = document.nodes.first? || begin
        scalar = ::YAML::Nodes::Scalar.new("")
        scalar.style = ::YAML::ScalarStyle::PLAIN
        scalar
      end

      new ::YAML::ParseContext.new, node
    end

    def new(node : ::YAML::Nodes::Node)
      self.class.new @context, node
    end

    def deserialize(to type : ::YAML::Serializable.class | Any.class)
      type.new @context, @node
    end

    protected def de_unionize(object : U) forall U
      {% for u in U.union_types %}
        return deserialize object if object.is_a? {{u}}
      {% end %}
    end

    private def parse_scalar(type : T.class) forall T
      @context.read_alias(@node, T) do |obj|
        return obj
      end

      if (node = @node).is_a? ::YAML::Nodes::Scalar
        value = ::YAML::Schema::Core.parse_scalar node
        if value.is_a? T
          @context.record_anchor node, value
          value
        else
          @node.raise "Expected #{T}, not #{node.value}"
        end
      else
        @node.raise "Expected #{T}, not #{@node.class.name}"
      end
    end

    def deserialize(to type : Hash.class)
      node = @node
      @context.read_alias(@node, type) do |obj|
        return obj
      end
      if !node.is_a?(::YAML::Nodes::Mapping)
        node.raise "Expected mapping, not #{node.class}"
      end

      hash = type.new
      key_class, value_class = typeof(hash.first)

      @context.record_anchor(node, hash)
      ::YAML::Schema::Core.each(node) do |key_node, value_node|
        hash[new(key_node).deserialize key_class] = new(value_node).deserialize value_class
      end

      hash
    end

    def deserialize(to type : Array.class | Deque.class | Set.class)
      node = @node
      @context.read_alias(node, type) do |obj|
        return obj
      end
      if !node.is_a? ::YAML::Nodes::Sequence
        node.raise "Expected sequence, not #{node.class}"
      end

      array = type.new
      value_class = typeof(array.first)
      @context.record_anchor(node, array)

      node.each do |value_node|
        array << new(value_node).deserialize value_class
      end

      array
    end

    private def check_tuple_size(node : ::YAML::Nodes::Sequence, type : T.class) forall T
      if node.nodes.size != {{T.size}}
        node.raise "Expected #{{{T.size}}} elements, not #{node.nodes.size}"
      end
    end

    def deserialize(to type : Tuple.class)
      node = @node
      if !node.is_a? ::YAML::Nodes::Sequence
        node.raise "Expected sequence, not #{node.class}"
      end
      check_tuple_size node, type

      i = -1
      Crystalizer.create_tuple type do |value_type|
        i += 1
        new(node.nodes[i]).deserialize value_type
      end
    end

    def deserialize(to type : ::NamedTuple.class)
      node = @node
      if !node.is_a? ::YAML::Nodes::Mapping
        node.raise "Expected mapping, not #{node.class}"
      end

      deserializer = Crystalizer::Deserializer::NamedTupleObject.new type
      ::YAML::Schema::Core.each(node) do |key_node, value_node|
        key = String.new(@context, key_node)
        deserializer.set_value key do |value_type|
          new(value_node).de_unionize value_type
        end
      end

      deserializer.named_tuple
    end

    def deserialize(to type : Enum.class)
      node = @node
      if !node.is_a? ::YAML::Nodes::Scalar
        node.raise "Expected scalar, not #{node.class}"
      end

      string = node.value
      if value = string.to_i64?
        type.from_value value
      else
        type.parse string
      end
    end

    def deserialize(to type : Bool.class | Nil.class | Time.class | Slice(UInt8).class)
      parse_scalar type
    end

    def deserialize(to float : Float.class)
      float.new! parse_scalar Float64
    end

    def deserialize(to int : Int.class)
      int.new! parse_scalar Int64
    end

    def deserialize(to type : Path.class)
      Path.new deserialize String
    end

    def deserialize(to type : String.class)
      @context.read_alias(@node, String) do |obj|
        return obj
      end

      if (node = @node).is_a? ::YAML::Nodes::Scalar
        value = node.value
        @context.record_anchor node, value
        value
      else
        @node.raise "Expected String, not #{@node.class.name}"
      end
    end

    protected def deserialize_union(type : T.class) forall T
      node = @node
      if node.is_a? ::YAML::Nodes::Alias
        {% for type in T.union_types %}
          {% if type < ::Reference %}
            @context.read_alias?(node, {{type}}) do |obj|
              return obj
            end
          {% end %}
        {% end %}

        node.raise "Error deserializing alias"
      end

      {% begin %}
        # String must come last because anything can be parsed into a String.
        # So, we give a chance first to types in the union to be parsed.
        {% string_type = T.union_types.find { |t_type| t_type == ::String } %}

        {% for type in T.union_types %}
          {% unless type == string_type %}
            begin
              return deserialize {{type}}
            rescue ::YAML::ParseException
              # Ignore
            end
          {% end %}
        {% end %}

        {% if string_type %}
          begin
            return deserialize {{string_type}}
          rescue ::YAML::ParseException
            # Ignore
          end
        {% end %}
      {% end %}

      node.raise "Couldn't parse #{type}"
    end

    def deserialize(to type : T.class) : T forall T
      {% if T.union_types.size > 1 %}
        deserialize_union type
      {% elsif T < Array || T < Deque || T < Set || T < Hash %}
        deserialize type
      {% else %}
        deserializer = Crystalizer::Deserializer::SelfDescribingObject.new type
        case node = @node
        when ::YAML::Nodes::Mapping
          ::YAML::Schema::Core.each(node) do |key_node, value_node|
            unless key_node.is_a?(::YAML::Nodes::Scalar)
              key_node.raise "Expected scalar as key for mapping"
            end

            key = key_node.value
            deserializer.set_ivar key do |variable|
              if variable.nilable || variable.has_default
                ::YAML::Schema::Core.parse_null_or(value_node) do
                  new(value_node).de_unionize variable.type
                end
              else
                new(value_node).de_unionize variable.type
              end
            end
          end
        when ::YAML::Nodes::Scalar
          if node.value.empty? && node.style.plain? && !node.tag
            # We consider an empty scalar as an empty mapping
          else
            node.raise "Expected mapping, not #{node.class}"
          end
        else
          node.raise "Expected mapping, not #{node.class}"
        end
        deserializer.object_instance
      {% end %}
    end
  end
end
