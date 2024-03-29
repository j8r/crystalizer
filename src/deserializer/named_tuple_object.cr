struct Crystalizer::Deserializer::NamedTupleObject(U, NT, N)
  class Error < Exception
  end

  @variables = StaticArray(U, N).new nil

  def self.new(type : ::NamedTuple.class)
    internal_new type
  end

  private def self.internal_new(type : NT.class)
    {% begin %}
    {% types = NT.keys.map { |k| NT[k] }; types << Nil %}
    Deserializer::NamedTupleObject({{ types.join(" | ").id }}, NT, {{NT.size}}).new
    {% end %}
  end

  # Sets the value of `key`, and yields its type class.
  def set_value(key : String, &)
    {% begin %}
      {% i = 0 %}
      case key
      {% for key, type in NT %}
      when {{key.stringify}}
        @variables[{{i}}] = yield({{type}}).as({{type}})
        {% i += 1 %}
      {% end %}
      else raise Error.new "Missing key in {{NT}}: #{key}"
      end
    {% end %}
  end

  # Returns the deserialized `NamedTuple` instance.
  def named_tuple : NT
    {% begin %}
    {% i = 0 %}
      {
      {% for key, type in NT %}
        {{key}}: (
          case value = @variables[{{i}}]
          when nil      then {% if !type.nilable? %} raise Error.new "Missing {{key}} value." {% end %}
          when {{type}} then value
          else          raise Error.new "Incorrect type for {{key}}: #{value}"
          end
        ),
      {% i += 1 %}
      {% end %}
      }
    {% end %}
  end

  def size
    {{NT.size}}
  end
end
