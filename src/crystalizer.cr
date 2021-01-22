require "./ext/object"
require "./field"
require "./object"
require "./variable"

module Crystalizer
  # Creates a new `Tuple` instance from a Tuple class.
  protected def self.create_tuple(tuple : Tuple.class, &)
    internal_create_tuple tuple do |type|
      yield type
    end
  end

  private def self.internal_create_tuple(tuple : T.class, &) : T forall T
    {% begin %}
      Tuple.new(
        {% for type in T.type_vars %}
         yield({{type}}).as({{type}}),
        {% end %}
      )
   {% end %}
  end
end
