# Annotations are similar to the stdlib's `Serializable`, but all features are not yet fully implemented.
#
# ```
# struct Strukt
#   @[Crystalizer::Field(ignore: true, key: "Var")]
#   @var : Int32
# end
# ```
annotation Crystalizer::Field
end
