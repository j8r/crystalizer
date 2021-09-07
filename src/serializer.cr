require "./type"

# Serializer interface to be included
module Crystalizer::Serializer
  abstract def serialize(object : O) forall O

  macro included
    def serialize(type : Crystalizer::Type)
      type.serialize self
    end
  end
end
