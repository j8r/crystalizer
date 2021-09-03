require "./crystalizer"
require "./deserializer"
require "./deserializer/self_describing_object"
require "./any"
require "./format"
require "./serializer"
require "json"
require "./json/*"

module Crystalizer::JSON
  extend Format

  class Error < Exception
  end
end
