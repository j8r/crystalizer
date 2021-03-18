require "./object"

struct Crystalizer::Deserializer::NonSelfDescribingObject(T)
  include Deserializer::Object(T)

  @ran = false

  def self.new(type : T.class)
    init NonSelfDescribingObject(T)
  end

  # Yields each instance variable's `Variable` metadata and it value.
  #
  # This method can be used for non self-describing formats (which does not holds keys).
  def set_each_ivar(&)
    {% for ivar in T.instance_vars %}
      {% ann = ivar.annotation(::Crystalizer::Field) %}
      {% unless ann && (ann[:ignore] || ann[:ignore_deserialize])%}
        {% key = ((ann && ann[:key]) || ivar).id.stringify %}
        variable = Variable.new(
          type: {{ivar.type}},
          annotations: {{ann && ann.named_args}},
          nilable: false,
          has_default: {{ivar.has_default_value?}}
        )
        pointerof(@object_instance.@{{ivar}}).value = yield(variable).as {{ivar.type}}
      {% end %}
    {% end %}
    @ran = true
  end

  def object_instance : T
    raise Error.new "#set_each_ivar not previously called: no instance variable set." if !@ran
    @object_instance
  end
end
