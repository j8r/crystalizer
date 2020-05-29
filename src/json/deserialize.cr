module Crystalizer::JSON
  def deserialize(string_or_io : String | IO, to type : O.class) : O forall O
    pull = ::JSON::PullParser.new(string_or_io)
    deserialize pull, to: type
  end

  def deserialize(
    pull : ::JSON::PullParser,
    to type : (::JSON::Serializable | Bool | Float | Int | NamedTuple | Nil | String | Symbol | Time).class
  )
    type.new pull
  end

  def deserialize(pull : ::JSON::PullParser, to type : Hash.class)
    hash = type.new
    key_class, value_class = typeof(hash.first)

    pull.read_object do |key, key_location|
      if parsed_key = key_class.from_json_object_key?(key)
        hash[parsed_key] = deserialize pull, value_class
      else
        raise ::JSON::ParseException.new("Can't convert #{key.inspect} into #{key_class}", *key_location)
      end
    end

    hash
  end

  def deserialize(pull : ::JSON::PullParser, to type : Array.class | Deque.class | Set.class)
    array = type.new
    value_class = typeof(array.first)
    pull.read_array do
      array << deserialize pull, value_class
    end
    array
  end

  def deserialize(pull : ::JSON::PullParser, to type : Tuple.class)
    pull.read_begin_array
    tuple = Crystalizer.create_tuple type do |value_type|
      deserialize pull, value_type
    end
    pull.read_end_array
    tuple
  end

  def deserialize(pull : ::JSON::PullParser, to type : Enum.class)
    case pull.kind
    when .int?
      type.from_value(pull.read_int)
    when .string?
      type.parse(pull.read_string)
    else
      raise Exception.new "Expecting int or string in JSON for #{type}, not #{pull.kind}"
    end
  end

  def deserialize(pull : ::JSON::PullParser, to type : O.class) : O forall O
    deserializer = Crystalizer::Deserializer.new type
    pull.read_begin_object
    while !pull.kind.end_object?
      key = pull.read_object_key
      deserializer.set_ivar key do |variable|
        if variable.nilable || variable.has_default
          pull.read_null_or do
            deserialize pull, variable.type
          end
        else
          deserialize pull, variable.type
        end
      end
    end
    deserializer.object_instance
  end
end
