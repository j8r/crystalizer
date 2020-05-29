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

  def deserialize(
    ctx : ::YAML::ParseContext,
    node : ::YAML::Nodes::Node,
    to type : (::YAML::Serializable | Bool | Float | Hash | Int | NamedTuple | Nil | String | Symbol | Time).class
  )
    type.new ctx, node
  end

  def deserialize(ctx : ::YAML::ParseContext, node : ::YAML::Nodes::Node, to type : Hash.class)
    ctx.read_alias(node, type) do |obj|
      return obj
    end
    if !node.is_a?(::YAML::Nodes::Mapping)
      node.raise "Expected mapping, not #{node.class}"
    end

    hash = type.new
    key_class, value_class = typeof(hash.first)

    ctx.record_anchor(node, hash)
    ::YAML::Schema::Core.each(node) do |key, value|
      hash[deserialize(ctx, key, key_class)] = deserialize(ctx, value, value_class)
    end

    hash
  end

  def deserialize(ctx : ::YAML::ParseContext, node : ::YAML::Nodes::Node, to type : Array.class | Deque.class | Set.class)
    ctx.read_alias(node, type) do |obj|
      return obj
    end
    if !node.is_a?(::YAML::Nodes::Sequence)
      node.raise "Expected sequence, not #{node.class}"
    end

    array = type.new
    value_class = typeof(array.first)
    ctx.record_anchor(node, array)

    node.each do |value_node|
      array << deserialize ctx, value_node, value_class
    end

    array
  end

  private def check_tuple_size(node : ::YAML::Nodes::Node, type : T.class) forall T
    if node.nodes.size != {{T.size}}
      node.raise "Expected #{{{T.size}}} elements, not #{node.nodes.size}"
    end
  end

  def deserialize(ctx : ::YAML::ParseContext, node : ::YAML::Nodes::Node, to type : Tuple.class)
    if !node.is_a?(::YAML::Nodes::Sequence)
      node.raise "Expected sequence, not #{node.class}"
    end
    check_tuple_size node, type

    i = -1
    tuple = Crystalizer.create_tuple type do |value_type|
      i += 1
      deserialize ctx, node.nodes[i], value_type
    end
  end

  def deserialize(ctx : ::YAML::ParseContext, node : ::YAML::Nodes::Node, to type : Enum.class)
    if !node.is_a?(::YAML::Nodes::Scalar)
      node.raise "Expected scalar, not #{node.class}"
    end

    string = node.value
    if value = string.to_i64?
      type.from_value(value)
    else
      type.parse(string)
    end
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
end
