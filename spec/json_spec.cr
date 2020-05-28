require "spec"
require "../src/json"

struct JSONPoint
  getter x : Int32
  @[Crystalizer::Field(key: "Y")]
  getter y : String

  def initialize(@x, @y)
  end
end

class JSONObj
  getter ary

  def initialize(@ary : Array(String))
  end

  def ==(other : self)
    @ary == other.ary
  end
end

def assert_json_serialization(object : T, string : String) forall T
  it "serializes" do
    Crystalizer::JSON.serialize(object, indent: "").should eq string
  end

  it "deserializes" do
    Crystalizer::JSON.deserialize(string, to: T).should eq object
  end
end

describe Crystalizer::JSON do
  describe "struct" do
    point = JSONPoint.new 1, "a"
    json_point = %({"x":1,"Y":"a"})

    assert_json_serialization point, json_point
  end

  describe "class" do
    obj = JSONObj.new ["a", "b"]
    json_obj = %({"ary":["a","b"]})

    assert_json_serialization obj, json_obj
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
end
