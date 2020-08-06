# Annotation to add information of how (de)serialize the object.
#
# `fields_order` takes a list of instance variable, used to explicitly define the (de)serialization order.
# It matters for some protocols (like binary/bytes-oriented ones).
# This option can also be used to only (de)serialize a set of instance variables, and ignore those not.
#
# ```
# @[Crystalizer::Object(fields_order: %w(var other))]
# struct Strukt
#   @var : Int32
#   @other : String
# end
# ```
annotation Crystalizer::Object
end
