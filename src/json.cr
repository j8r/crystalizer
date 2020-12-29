require "./crystalizer"
require "./deserializer"
require "./deserializer/self_describing_object"
require "./any"
require "json"
require "./json/*"

module Crystalizer::JSON
  class Error < Exception
  end
end
