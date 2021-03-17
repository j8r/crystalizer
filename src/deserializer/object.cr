module Crystalizer::Deserializer::Object(T)
  class Error < Exception
  end

  @object_instance : T

  private macro init(object)
    \{% if T < Enum %}
      raise Error.new "Enum type not expected here: #{T}"
    \{% elsif T.abstract? %}
      case type
      \{% for type in T.all_subclasses %}
      when .== \{{type}} then new \{{type}}
      \{% end %}
      else
        raise Error.new "Unreachable type: #{type}"
      end
    \{% else %}
       {{object.id}}.new
    \{% end %}
  end

  def initialize
    instance = T.allocate
    GC.add_finalizer(instance) if instance.responds_to?(:finalize)
    @object_instance = instance
  end

  abstract def object_instance : T
end
