# Format interface
module Crystalizer::Format
  abstract def serializer(io : IO, & : Crystalizer::Serializer ->) : Nil
  abstract def deserializer(object) : Crystalizer::Deserializer
end
