require "spec"
require "../src/yaml"

struct YAMLPoint
  getter x : Int32
  @[Crystalizer::Field(key: "Y")]
  getter y : String

  def initialize(@x, @y)
  end
end

class YAMLObj
  getter ary

  def initialize(@ary : Array(String))
  end

  def ==(other : self)
    @ary == other.ary
  end
end

def assert_yaml_serialization(object : T, string : String) forall T
  it "serializes" do
    Crystalizer::YAML.serialize(object).should eq string
  end

  it "deserializes" do
    Crystalizer::YAML.deserialize(string, to: T).should eq object
  end
end

describe Crystalizer::YAML do
  describe "struct" do
    point = YAMLPoint.new 1, "a"
    yaml_point = <<-E
    ---
    x: 1
    Y: a

    E

    assert_yaml_serialization point, yaml_point
  end

  describe "class" do
    obj = YAMLObj.new ["a", "b"]
    yaml_obj = <<-E
    ---
    ary:
    - a
    - b

    E

    assert_yaml_serialization obj, yaml_obj
  end

  describe Hash do
    assert_yaml_serialization({"a" => 123}, <<-E
    ---
    a: 123

    E
    )
  end

  describe Array do
    assert_yaml_serialization(["a", 2], <<-E
    ---
    - a
    - 2

    E
    )
  end

  describe Tuple do
    assert_yaml_serialization({"a", 2}, <<-E
    ---
    - a
    - 2

    E
    )
  end
end
