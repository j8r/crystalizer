require "./type"

# Serializer interface to be included
module Crystalizer::Serializer
  abstract def serialize(object : O) forall O

  macro included
    def serialize(object : Crystalizer::Type)
      object.serialize self
    end
  end
end
