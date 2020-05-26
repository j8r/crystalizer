require "./field"

struct Crystalizer::Deserializer(T, N)
  class Exception < ::Exception
  end

  struct Variable(T)
    protected getter index : Int32
    getter type : T.class = T
    getter nilable : Bool
    getter has_default : Bool

    def initialize(@nilable : Bool, @has_default : Bool, @index : Int32 = 0)
    end
  end

  @found = StaticArray(Bool, N).new false
  @object_instance : T

  def initialize
    instance = T.allocate
    GC.add_finalizer(instance) if instance.responds_to?(:finalize)
    @object_instance = instance
  end

  def self.new(type : T.class) forall T
    {% begin %}
    Deserializer(T, {{T.instance_vars.size}}).new
    {% end %}
  end

  # Sets an object_instance variable for a key.
  def set_ivar(key : String, &)
    {% begin %}
    {% index = 0 %}
    case key
    {% for ivar in T.instance_vars %}
      {% ann = ivar.annotation(::Crystalizer::Field) %}
      {% unless ann && ann[:ignore] %}
        {%
          type = ivar.type
          key = ((ann && ann[:key]) || ivar).id.stringify
        %}
        when {{key}}
          raise Exception.new "duplicated key: #{key}" if @found[{{index}}]
          @found[{{index}}] = true
          variable = Variable({{type}}).new(
            nilable: {{ivar.type.nilable?}},
            has_default: {{ivar.has_default_value?}},
            index: {{index}}
          )
          pointerof(@object_instance.@{{ivar}}).value = yield(variable).as {{type}}
        {% end %}
        {% index = index + 1 %}
      {% end %}
      else raise Exception.new "Missing key in {{T}}: #{key}"
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
          @object_instance.@{{ivar}} = {{ivar.default_value}}
        {% elsif !ivar.type.nilable? %}
          raise Exception.new "{{ivar}} not found in {{T}}"
        {% end %}
      end
      {% end %}
      {% i = i + 1 %}
    {% end %}
    {% end %}
  end

  # Returns the deserialized object instance.
  def object_instance : T
    check_ivars
    @object_instance
  end
end
