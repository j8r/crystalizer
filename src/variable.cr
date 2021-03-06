# Holds variable metadata with its annotations.
struct Crystalizer::Variable(T, A)
  getter type : T.class = T
  getter nilable : Bool
  getter has_default : Bool
  getter annotations : A

  def initialize(@type : T.class, @annotations : A, @nilable : Bool, @has_default : Bool)
  end
end
