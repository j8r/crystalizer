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
        deserialize pull, variable.type
      end
    end
    deserializer.object_instance
  end

  def deserialize(
    pull : ::JSON::PullParser,
    to type : (::JSON::Serializable | Array | Bool | Enum | Float | Hash | Int | NamedTuple | Nil | Set | String | Symbol | Time | Tuple).class
  )
    type.new pull
  end
end
