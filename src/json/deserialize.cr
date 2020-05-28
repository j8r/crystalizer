module Crystalizer::JSON
  def deserialize(string_or_io : String | IO, to type : O.class) : O forall O
    pull = ::JSON::PullParser.new(string_or_io)
    deserialize pull, to: type
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

  def deserialize(
    pull : ::JSON::PullParser,
    to type : (::JSON::Serializable | Array | Bool | Enum | Float | Int | NamedTuple | Nil | Set | String | Symbol | Time | Tuple).class
  )
    type.new pull
  end

  def deserialize(pull : ::JSON::PullParser, to type : Hash.class)
    hash = type.new
    key_class, value_class = typeof(hash.first)

    pull.read_object do |key, key_location|
      parsed_key = key_class.from_json_object_key?(key)
      unless parsed_key
        raise ::JSON::ParseException.new("Can't convert #{key.inspect} into #{key_class}", *key_location)
      end
      hash[parsed_key] = deserialize pull, value_class
    end

    hash
  end
end
