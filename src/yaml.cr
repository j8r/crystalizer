require "./crystalizer"
require "./deserializer"
require "./deserializer/self_describing_object"
require "./any"
require "./format"
require "./serializer"
require "yaml"
require "./yaml/*"

module Crystalizer::YAML
  extend Format

  class Error < Exception
  end
end
