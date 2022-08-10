# Format interface
module Crystalizer::Format
  abstract def serialize(io : IO, object)
  abstract def deserialize(io : IO, to type : T.class) forall T
end
