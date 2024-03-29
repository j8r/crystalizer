require "spec"
require "../src/yaml"
require "./format_helper"

private def assert_yaml_serialization(object : T, string : String, line = __LINE__) forall T
  it "serializes", line: line do
    Crystalizer::YAML.serialize(object).should eq string
  end

  it "deserializes", line: line do
    Crystalizer::YAML.deserialize(string, to: T).should eq object
  end
end

describe Crystalizer::YAML do
  describe "struct" do
    point = Point.new 1
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
    one: 1
    ary0:
    - 0
    ary:
    - a
    - b

    E

    assert_yaml_serialization obj, yaml_obj
  end

  describe "nested class" do
    nested = Nested.new("bar")
    obj = Parent.new("foo", nested)
    yaml_obj = <<-E
    ---
    str: foo
    nested:
      str: bar

    E

    assert_yaml_serialization obj, yaml_obj
  end

  describe Crystalizer::YAML::Any do
    yaml = <<-E
    ---
    ary:
    - a
    - 1

    E
    any = Crystalizer::YAML.parse yaml
    assert_yaml_serialization any, yaml
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
    assert_yaml_serialization(Enu::A, "--- a\n")
  end

  describe NamedTuple do
    assert_yaml_serialization({a: "A", b: 1}, <<-E
    ---
    a: A
    b: 1

    E
    )

    assert_yaml_serialization({a: "A", ary_union: [1, "a"]}, <<-E
    ---
    a: A
    ary_union:
    - 1
    - a

    E
    )
  end

  describe Bool do
    assert_yaml_serialization(true, "--- true\n")
  end

  describe Float do
    assert_yaml_serialization(1.5_f32, "--- 1.5\n")
    assert_yaml_serialization(1.5_f64, "--- 1.5\n")
  end

  describe Int do
    assert_yaml_serialization(1, "--- 1\n")
    assert_yaml_serialization(1_u64, "--- 1\n")
  end

  describe String do
    assert_yaml_serialization("a", "--- a\n")
  end

  describe Symbol do
    it "serializes" do
      Crystalizer::YAML.serialize(:a).should eq "--- a\n"
    end
  end

  describe Nil do
    if YAML.libyaml_version < SemanticVersion.new(0, 2, 5)
      assert_yaml_serialization(nil, "--- \n")
    else
      assert_yaml_serialization(nil, "---\n")
    end
  end

  describe Time do
    assert_yaml_serialization Time.utc(2020, 1, 2, 3), "--- 2020-01-02 03:00:00.000000000\n"
  end

  describe Slice(UInt8) do
    assert_yaml_serialization "abc".to_slice, "--- !!binary 'YWJj\n\n  '\n"
  end

  describe "compiles when an object has two enum ivars" do
    assert_yaml_serialization ObjWithEnum.new, "---\ni: 1\nenu1: a\nother: [b]\n"
  end

  describe Crystalizer::Type do
    it "serializes a custom type" do
      Crystalizer::YAML.serialize(TestCustomTypeSerialization.new 3).should eq "--- 3\n"
    end

    it "deserializes a custom type" do
      Crystalizer::YAML.deserialize("3", to: TestCustomTypeSerialization).should eq TestCustomTypeSerialization.new 3
    end

    it "serializes a type with a custom one inside" do
      Crystalizer::YAML.serialize(CustomSub.new).should eq "---\nstr: abc\ncustom: 1\n"
    end

    it "deserializes a type with a custom one inside" do
      Crystalizer::YAML.deserialize("---\nstr: abc\ncustom: 1\n", to: CustomSub).should eq CustomSub.new
    end
  end
end
