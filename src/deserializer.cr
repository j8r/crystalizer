# Deserializer interface to be extended.
module Crystalizer::Deserializer
  abstract def deserialize(to type : T.class) forall T

  macro included
    def deserialize(to type : Crystalizer::Type.class)
      type.deserialize self
    end
  end
end

require "./field"
require "./variable"
require "./crystalizer"
require "./deserializer/named_tuple_object"
