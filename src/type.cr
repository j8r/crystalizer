require "./deserializer"
require "./serializer"

# Including this type allows to define custom serialization and deserialization for a given type.
#
# ```
# struct MyType
#   include Crystalizer::Type
#
#   def initialize(@i : Int32)
#   end
#
#   def self.deserialize(deserializer : Crystalizer::Deserializer)
#     new deserializer.deserialize to: Int32
#   end
#
#   def serialize(serializer : Crystalizer::Serializer) : Nil
#     serializer.serialize @i
#   end
# end
# ```
module Crystalizer::Type
  abstract def serialize(serializer : Crystalizer::Serializer) : Nil

  private module Deserialize
    abstract def deserialize(deserializer : Crystalizer::Deserializer)
  end

  macro included
    extend Deserialize
  end
end
