# Derializer interface
module Crystalizer::Deserializer
  abstract def deserialize(to type : T.class) forall T
end

require "./field"
require "./variable"
require "./crystalizer"
require "./deserializer/named_tuple_object"
