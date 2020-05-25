require "./field"

module Crystalizer
  def self.each_ivar(object : O, &) forall O
    {% for ivar in O.instance_vars %}
      {% ann = ivar.annotation(::Crystalizer::Field) %}
      {% unless ann && ann[:ignore] %}
        {%
          key = ((ann && ann[:key]) || ivar).id.stringify
        %}
        yield {{key}}, object.@{{ivar}}
      {% end %}
    {% end %}
  end
end
