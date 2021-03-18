# Annotations are similar to the stdlib's `Serializable`, but all features are not yet fully implemented.
#
# ```
# struct Strukt
#   @[Crystalizer::Field(ignore: true, key: "Var")]
#   @var : Int32
# end
# ```
# `Crystalizer::Field` properties:
# - **ignore**: if `true` skip this field in serialization and deserialization (by default `false`)
# - **ignore_serialize**: if `true` skip this field in serialization (by default `false`)
# - **ignore_deserialize**: if `true` skip this field in deserialization (by default `false`)
# - **key**: the value of the key in the json object (by default the name of the instance variable)
annotation Crystalizer::Field
end
