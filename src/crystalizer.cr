require "./field"
require "./variable"

module Crystalizer
  # Yields each ivar with its key, value, `Variable` metadata.
  def self.each_ivar(object : O, &) forall O
    {% for ivar in O.instance_vars %}
      {% ann = ivar.annotation(::Crystalizer::Field) %}
      {% unless ann && ann[:ignore] %}
        {% key = ((ann && ann[:key]) || ivar).id.stringify %}
        yield {{key}}, object.@{{ivar}}, Variable.new(
            type: {{ivar.type}},
            annotations: {{ann && ann.named_args}},
            nilable: {{ivar.type.nilable?}},
            has_default: {{ivar.has_default_value?}}
          )
      {% end %}
    {% end %}
  end
end
