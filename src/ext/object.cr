class Object
  def each_ivar(&block)
    {% begin %}
      {% for ivar in @type.instance_vars %}
        {% ann = ivar.annotation(::Crystalizer::Field) %}
        {% unless ann && ann[:ignore] %}
          {% key = ((ann && ann[:key]) || ivar).id.stringify %}
          yield {{key}}, @{{ivar}}, Crystalizer::Variable.new(
              type: {{ivar.type}},
              annotations: {{ann && ann.named_args}},
              nilable: {{ivar.type.nilable?}},
              has_default: {{ivar.has_default_value?}}
            )
        {% end %}
      {% end %}
    {% end %}
  end
end
