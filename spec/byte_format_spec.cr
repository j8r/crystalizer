require "spec"
require "../src/byte_format"

module ByteFormatTest
  struct Point
    @x = 1
    @y = "a"
  end

  enum Abc : UInt8
    A
    B
    C
  end

  class Obj
    getter x = 1, y = "a"

    def ==(other : self)
      @x == other.x && @y == other.y
    end
  end
end

private def assert_byte_format_serialization(object : T, bytes : Bytes, line = __LINE__) forall T
  it "serializes", line: line do
    Crystalizer::ByteFormat.serialize(object).should eq bytes
  end

  it "deserializes", line: line do
    Crystalizer::ByteFormat.deserialize(bytes, to: T).should eq object
  end
end

describe Crystalizer::ByteFormat do
  describe "struct" do
    point = ByteFormatTest::Point.new
    bytes = Bytes[1, 0, 0, 0, 97, 0]

    assert_byte_format_serialization point, bytes
  end

  describe "class" do
    point = ByteFormatTest::Obj.new
    bytes = Bytes[1, 0, 0, 0, 97, 0]

    assert_byte_format_serialization point, bytes
  end

  describe "nested class" do
    nested = Nested.new("bar")
    obj = Parent.new("foo", nested)
    bytes = Bytes[102, 111, 111, 0, 98, 97, 114, 0]

    assert_byte_format_serialization obj, bytes
  end

  describe Array do
    assert_byte_format_serialization([1, 2], Bytes[1, 0, 0, 0, 2, 0, 0, 0])
  end

  describe Tuple do
    assert_byte_format_serialization({"a", 2}, Bytes[97, 0, 2, 0, 0, 0])
  end

  describe Enum do
    assert_byte_format_serialization(ByteFormatTest::Abc::B, Bytes[1])
  end

  describe NamedTuple do
    assert_byte_format_serialization({a: "a", b: 1}, Bytes[97, 0, 97, 0, 98, 0, 1, 0, 0, 0])
  end

  describe Bool do
    assert_byte_format_serialization(false, Bytes[0])
    assert_byte_format_serialization(true, Bytes[1])
  end

  describe Float do
    assert_byte_format_serialization(1.5_f32, Bytes[0, 0, 192, 63])
    assert_byte_format_serialization(1.5_f64, Bytes[0, 0, 0, 0, 0, 0, 248, 63])
  end

  describe Int do
    assert_byte_format_serialization(1, Bytes[1, 0, 0, 0])
    assert_byte_format_serialization(1_u64, Bytes[1, 0, 0, 0, 0, 0, 0, 0])
  end

  describe Hash do
    assert_byte_format_serialization({"a" => 123}, Bytes[97, 0, 123, 0, 0, 0])
  end

  describe String do
    assert_byte_format_serialization("abc", Bytes[97, 98, 99, 0])
  end

  describe Symbol do
    it "serializes" do
      Crystalizer::ByteFormat.serialize(:a).should eq Bytes[97, 0]
    end
  end
end
