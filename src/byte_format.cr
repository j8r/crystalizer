# Byte format, as implemented in the stdlib: https://crystal-lang.org/api/master/IO/ByteFormat.html.
#
# Important note: bytes representation of dynamic data structures like `Array` and `Hash` have no end delimiter.
# On an object, only one of it can be present as the last instance variable, otherwise they will collide with the next ones - having no delimiter to separate them.
#
# Unions are also not supported.
struct Crystalizer::ByteFormat
  class Error < Exception
  end

  getter io : IO

  # Byte to delimit the end of a `String`.
  class_property byte_delimiter : UInt8? = 0_u8

  def initialize(
    @io : IO = IO::Memory.new,
    @format : IO::ByteFormat = IO::ByteFormat::SystemEndian,
    @byte_delimiter : UInt8? = @@byte_delimiter
  )
  end
end

require "./crystalizer"
require "./deserializer"
require "./deserializer/non_self_describing_object"
require "./byte_format/*"
