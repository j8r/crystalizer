struct Crystalizer::Deserializer::Object(T, N)
  class Error < Exception
  end

  @found = StaticArray(Bool, N).new false
  @object_instance : T

  def initialize
    instance = T.allocate
    GC.add_finalizer(instance) if instance.responds_to?(:finalize)
    @object_instance = instance
  end

  def self.new(type : T.class)
    {% begin %}
    Deserializer::Object(T, {{T.instance_vars.size}}).new
    {% end %}
  end

  # Yields each instance variable's `Variable` metadata and it value.
  #
  # This method can be used for non self-describing formats (which does not holds keys).
  def set_each_ivar(&)
    {% begin %}
    {% i = 0 %}
    {% for ivar in T.instance_vars %}
      {% ann = ivar.annotation(::Crystalizer::Field) %}
      {% unless ann && ann[:ignore] %}
        {% key = ((ann && ann[:key]) || ivar).id.stringify %}
        @found[{{i}}] = true
        variable = Variable.new(
          type: {{ivar.type}},
          annotations: {{ann && ann.named_args}},
          nilable: {{ivar.type.nilable?}},
          has_default: {{ivar.has_default_value?}}
        )
        pointerof(@object_instance.@{{ivar}}).value = yield(variable).as {{ivar.type}}
        {% i += 1 %}
      {% end %}
    {% end %}
    {% end %}
  end

  # Sets a value for an instance variable corresponding to the key.
  def set_ivar(key : String, &)
    {% begin %}
    {% i = 0 %}
    case key
    {% for ivar in T.instance_vars %}
      {% ann = ivar.annotation(::Crystalizer::Field) %}
      {% unless ann && ann[:ignore] %}
        {% key = ((ann && ann[:key]) || ivar).id.stringify %}
        when {{key}}
          raise Error.new "Duplicated field for {{T}}: #{key}" if @found[{{i}}]
          @found[{{i}}] = true
          variable = Variable.new(
            type: {{ivar.type}},
            annotations: {{ann && ann.named_args}},
            nilable: {{ivar.type.nilable?}},
            has_default: {{ivar.has_default_value?}}
          )
          pointerof(@object_instance.@{{ivar}}).value = yield(variable).as {{ivar.type}}
        {% end %}
        {% i += 1 %}
      {% end %}
      else raise Error.new "Unknown field in {{T}} matching the given string: #{key}"
      end
    {% end %}
  end

  private def check_ivars
    {% begin %}
    {% i = 0 %}
    {% for ivar in T.instance_vars %}
      {% ann = ivar.annotation(::Crystalizer::Field) %}
      {% unless ann && ann[:ignore] %}
      if !@found[{{i}}]
        {% if ivar.has_default_value? %}
          pointerof(@object_instance.@{{ivar}}).value = {{ivar.default_value}}
        {% elsif !ivar.type.nilable? %}
          raise Error.new "Missing instance variable value in {{T}}: {{ivar}}"
        {% end %}
      end
      {% end %}
      {% i += 1 %}
    {% end %}
    {% end %}
  end

  # Returns the deserialized object instance.
  def object_instance : T
    check_ivars
    @object_instance
  end
end
