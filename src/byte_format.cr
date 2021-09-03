require "./format"

# Byte format, as implemented in the stdlib: https://crystal-lang.org/api/master/IO/ByteFormat.html.
#
# Important note: bytes representation of dynamic data structures like `Array` and `Hash` have no end delimiter.
# On an object, only one of it can be present as the last instance variable, otherwise they will collide with the next ones - having no delimiter to separate them.
#
# Unions are also not supported.
struct Crystalizer::ByteFormat
  extend Format

  class Error < Exception
  end

  getter io : IO
  property format : IO::ByteFormat
  property string_delimiter

  # Byte to delimit the end of a `String`.
  class_property string_delimiter : Char? = '\0'

  def initialize(
    @io : IO = IO::Memory.new,
    @format : IO::ByteFormat = IO::ByteFormat::SystemEndian,
    @string_delimiter : Char? = @@string_delimiter
  )
  end
end

require "./crystalizer"
require "./deserializer"
require "./deserializer/non_self_describing_object"
require "./serializer"
require "./byte_format/*"
