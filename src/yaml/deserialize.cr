module Crystalizer::YAML
  def deserialize(string_or_io : String | IO, to type : O.class) : O forall O
    document = ::YAML::Nodes.parse(string_or_io)

    # If the document is empty we simulate an empty scalar with
    # plain style, that parses to Nil
    node = document.nodes.first? || begin
      scalar = ::YAML::Nodes::Scalar.new("")
      scalar.style = ::YAML::ScalarStyle::PLAIN
      scalar
    end

    context = ::YAML::ParseContext.new
    deserialize context, node, to: type
  end

  def deserialize(ctx : ::YAML::ParseContext, node : ::YAML::Nodes::Node, to type : O.class) : O forall O
    deserializer = Crystalizer::Deserializer.new type
    case node
    when ::YAML::Nodes::Mapping
      ::YAML::Schema::Core.each(node) do |key_node, value_node|
        unless key_node.is_a?(::YAML::Nodes::Scalar)
          key_node.raise "Expected scalar as key for mapping"
        end

        key = key_node.value
        deserializer.set_ivar key do |variable|
          if variable.nilable || variable.has_default
            ::YAML::Schema::Core.parse_null_or(value_node) do
              deserialize ctx, value_node, variable.type
            end
          else
            deserialize ctx, value_node, variable.type
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
  end

  def deserialize(
    ctx : ::YAML::ParseContext,
    node : ::YAML::Nodes::Node,
    to type : (::YAML::Serializable | Array | Bool | Enum | Float | Hash | Int | NamedTuple | Nil | Set | String | Symbol | Time | Tuple).class
  )
    type.new ctx, node
  end
end
