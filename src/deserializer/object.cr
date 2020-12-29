module Crystalizer::Deserializer::Object(T)
  class Error < Exception
  end

  @object_instance : T

  def initialize
    instance = T.allocate
    GC.add_finalizer(instance) if instance.responds_to?(:finalize)
    @object_instance = instance
  end

  abstract def object_instance : T
end
