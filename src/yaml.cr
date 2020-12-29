require "./crystalizer"
require "./deserializer"
require "./deserializer/self_describing_object"
require "./any"
require "yaml"
require "./yaml/*"

module Crystalizer::YAML
  class Error < Exception
  end
end
