require "spec"
require "../src/yaml"
require "./format_helper"

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
    point = Point.new 1, "a"
    yaml_point = <<-E
    ---
    x: 1
    Y: a

    E

    assert_yaml_serialization point, yaml_point
  end

  describe "class" do
    obj = Obj.new ["a", "b"]
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

  describe Enum do
    assert_yaml_serialization(Enu::A, "--- 0\n")
  end
end
