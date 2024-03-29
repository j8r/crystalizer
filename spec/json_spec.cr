require "spec"
require "../src/json"
require "./format_helper"

private def assert_json_serialization(object : T, string : String, line = __LINE__) forall T
  it "serializes", line: line do
    Crystalizer::JSON.serialize(object, indent: "").should eq string
  end

  it "deserializes", line: line do
    Crystalizer::JSON.deserialize(string, to: T).should eq object
  end
end

describe Crystalizer::JSON do
  describe "struct" do
    assert_json_serialization Point.new(1), %({"x":1,"Y":"a"})
  end

  describe "class" do
    assert_json_serialization Obj.new(["a", "b"]), %({"one":1,"ary0":[0],"ary":["a","b"]})
  end

  describe "nested class" do
    assert_json_serialization(
      Parent.new("foo", Nested.new("bar")),
      %({"str":"foo","nested":{"str":"bar"}})
    )
  end

  describe Crystalizer::JSON::Any do
    json = %({"ary":["a",1]})
    any = Crystalizer::JSON.parse json
    assert_json_serialization any, json
  end

  describe Hash do
    assert_json_serialization({"a" => 123}, %({"a":123}))
  end

  describe Array do
    assert_json_serialization(["a", 2], %(["a",2]))
  end

  describe Tuple do
    assert_json_serialization({"a", 2}, %(["a",2]))
  end

  describe Enum do
    assert_json_serialization(Enu::A, %("a"))
  end

  describe NamedTuple do
    assert_json_serialization({a: "A", b: 1}, %({"a":"A","b":1}))

    assert_json_serialization({a: "A", ary_union: [1, "a"]}, %({"a":"A","ary_union":[1,"a"]}))
  end

  describe Bool do
    assert_json_serialization(true, "true")
  end

  describe Float do
    assert_json_serialization(1.5_f32, "1.5")
    assert_json_serialization(1.5_f64, "1.5")
  end

  describe Int do
    assert_json_serialization(1, "1")
    assert_json_serialization(1_u64, "1")
  end

  describe String do
    assert_json_serialization("a", %("a"))
  end

  describe Symbol do
    it "serializes" do
      Crystalizer::JSON.serialize(:a, indent: "").should eq %("a")
    end
  end

  describe Nil do
    assert_json_serialization(nil, "null")
  end

  describe Time do
    assert_json_serialization Time.utc(2020, 1, 2, 3), %("2020-01-02T03:00:00Z")
  end

  describe "compiles when an object has two enum ivars" do
    assert_json_serialization ObjWithEnum.new, %({"i":1,"enu1":"a","other":["b"]})
  end

  describe Crystalizer::Type do
    it "serializes a custom type" do
      Crystalizer::JSON.serialize(TestCustomTypeSerialization.new 3).should eq "3"
    end

    it "deserializes a custom type" do
      Crystalizer::JSON.deserialize("3", to: TestCustomTypeSerialization).should eq TestCustomTypeSerialization.new 3
    end

    it "serializes a type with a custom one inside" do
      Crystalizer::JSON.serialize(CustomSub.new).should eq %({\n  "str": "abc",\n  "custom": 1\n})
    end

    it "deserializes a type with a custom one inside" do
      Crystalizer::JSON.deserialize(%({\n  "str": "abc",\n  "custom": 1\n}), to: CustomSub).should eq CustomSub.new
    end
  end
end
