# Serializer interface
module Crystalizer::Serializer
  abstract def serialize(object : O) forall O
end
