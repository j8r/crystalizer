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

  struct StringGoodSize
    @[Crystalizer::Field(size: 5)]
    @a = "Short"
  end

  struct StringBadSize1
    @[Crystalizer::Field(size: 4)]
    @a = "Short"
  end

  struct StringBadSize2
    @[Crystalizer::Field(size: 6)]
    @a = "Short"
  end

  struct StringGoodRange1
    @[Crystalizer::Field(size: ..20)]
    @b = "Long description"
  end

  struct StringGoodRange2
    @[Crystalizer::Field(size: 10..)]
    @b = "Long description"
  end

  struct StringGoodRange3
    @[Crystalizer::Field(size: 10..20)]
    @b = "Long description"
  end

  struct StringGoodRange4
    @[Crystalizer::Field(size: ...20)]
    @b = "Long description"
  end

  struct StringGoodRange5
    @[Crystalizer::Field(size: 10...)]
    @b = "Long description"
  end

  struct StringGoodRange6
    @[Crystalizer::Field(size: 10...20)]
    @b = "Long description"
  end

  struct StringGoodRange7
    @[Crystalizer::Field(size: 16...20)]
    @b = "Long description"
  end

  struct StringGoodRange8
    @[Crystalizer::Field(size: 10..16)]
    @b = "Long description"
  end

  struct StringGoodRange9
    @[Crystalizer::Field(size: 10...17)]
    @b = "Long description"
  end

  struct StringBadRange1
    @[Crystalizer::Field(size: 6..)]
    @a = "Short"
  end

  struct StringBadRange2
    @[Crystalizer::Field(size: ..4)]
    @a = "Short"
  end

  struct StringBadRange3
    @[Crystalizer::Field(size: 6..8)]
    @a = "Short"
  end

  struct StringBadRange4
    @[Crystalizer::Field(size: 6..8)]
    @a = "Long description"
  end

  struct StringBadRange5
    @[Crystalizer::Field(size: 6...)]
    @a = "Short"
  end

  struct StringBadRange6
    @[Crystalizer::Field(size: ...4)]
    @a = "Short"
  end

  struct StringBadRange7
    @[Crystalizer::Field(size: 6...8)]
    @a = "Short"
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
    assert_byte_format_serialization(
      ByteFormatTest::Point.new,
      Bytes[1, 0, 0, 0, 97, 0]
    )
  end

  describe "class" do
    assert_byte_format_serialization(
      ByteFormatTest::Obj.new,
      Bytes[1, 0, 0, 0, 97, 0]
    )
  end

  describe "nested class" do
    assert_byte_format_serialization(
      Parent.new("foo", Nested.new("bar")),
      Bytes[102, 111, 111, 0, 98, 97, 114, 0]
    )
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
    describe "(de)serialization" do
      assert_byte_format_serialization("abc", Bytes[97, 98, 99, 0])

      # Bytes corresponding to `@a = "Long description"`
      bytes = Bytes[76, 111, 110, 103, 32, 100, 101, 115, 99, 114, 105, 112, 116, 105, 111, 110, 0]
      assert_byte_format_serialization(ByteFormatTest::StringGoodRange1.new, bytes)
      assert_byte_format_serialization(ByteFormatTest::StringGoodRange2.new, bytes)
      assert_byte_format_serialization(ByteFormatTest::StringGoodRange3.new, bytes)
      assert_byte_format_serialization(ByteFormatTest::StringGoodRange4.new, bytes)
      assert_byte_format_serialization(ByteFormatTest::StringGoodRange5.new, bytes)
      assert_byte_format_serialization(ByteFormatTest::StringGoodRange6.new, bytes)
      assert_byte_format_serialization(ByteFormatTest::StringGoodRange7.new, bytes)
      assert_byte_format_serialization(ByteFormatTest::StringGoodRange8.new, bytes)
      assert_byte_format_serialization(ByteFormatTest::StringGoodRange9.new, bytes)

      bytes = Bytes[83, 104, 111, 114, 116]
      assert_byte_format_serialization(ByteFormatTest::StringGoodSize.new, bytes)
      assert_byte_format_serialization(ByteFormatTest::StringGoodSize.new, bytes)
    end

    describe "deserialization" do
      bytes = Bytes[83, 104, 111, 114, 116]

      expect_raises Crystalizer::ByteFormat::Error, message: "String size not in range: 6..8" do
        Crystalizer::ByteFormat.deserialize(bytes, to: ByteFormatTest::StringBadRange4)
      end
      expect_raises Crystalizer::ByteFormat::Error, message: "String size not in range: 6.." do
        Crystalizer::ByteFormat.deserialize(bytes, to: ByteFormatTest::StringBadRange1)
      end
      expect_raises Crystalizer::ByteFormat::Error, message: "String size not in range: ..4" do
        Crystalizer::ByteFormat.deserialize(bytes, to: ByteFormatTest::StringBadRange2)
      end
      expect_raises Crystalizer::ByteFormat::Error, message: "String size not in range: 6..8" do
        Crystalizer::ByteFormat.deserialize(bytes, to: ByteFormatTest::StringBadRange3)
      end
      expect_raises Crystalizer::ByteFormat::Error, message: "String size not in range: 6.." do
        Crystalizer::ByteFormat.deserialize(bytes, to: ByteFormatTest::StringBadRange5)
      end
      expect_raises Crystalizer::ByteFormat::Error, message: "String size not in range: ...4" do
        Crystalizer::ByteFormat.deserialize(bytes, to: ByteFormatTest::StringBadRange6)
      end
      expect_raises Crystalizer::ByteFormat::Error, message: "String size not in range: 6...8" do
        Crystalizer::ByteFormat.deserialize(bytes, to: ByteFormatTest::StringBadRange7)
      end
    end

    describe "serialization" do
      expect_raises Crystalizer::ByteFormat::Error, message: "String size not in range: 6.. (have: 5)" do
        Crystalizer::ByteFormat.serialize(ByteFormatTest::StringBadRange1.new)
      end
      expect_raises Crystalizer::ByteFormat::Error, message: "String size not in range: ..4 (have: 5)" do
        Crystalizer::ByteFormat.serialize(ByteFormatTest::StringBadRange2.new)
      end
      expect_raises Crystalizer::ByteFormat::Error, message: "String size not in range: 6..8 (have: 5)" do
        Crystalizer::ByteFormat.serialize(ByteFormatTest::StringBadRange3.new)
      end
      expect_raises Crystalizer::ByteFormat::Error, message: "String size not in range: 6... (have: 5)" do
        Crystalizer::ByteFormat.serialize(ByteFormatTest::StringBadRange5.new)
      end
      expect_raises Crystalizer::ByteFormat::Error, message: "String size not in range: ...4 (have: 5)" do
        Crystalizer::ByteFormat.serialize(ByteFormatTest::StringBadRange6.new)
      end
      expect_raises Crystalizer::ByteFormat::Error, message: "String size not in range: 6...8 (have: 5)" do
        Crystalizer::ByteFormat.serialize(ByteFormatTest::StringBadRange7.new)
      end

      expect_raises Crystalizer::ByteFormat::Error, message: "String size not expected, expected: 4, have: 5" do
        Crystalizer::ByteFormat.serialize(ByteFormatTest::StringBadSize1.new)
      end
      expect_raises Crystalizer::ByteFormat::Error, message: "String size not expected, expected: 6, have: 5" do
        Crystalizer::ByteFormat.serialize(ByteFormatTest::StringBadSize2.new)
      end
    end
  end

  describe Symbol do
    it "serializes" do
      Crystalizer::ByteFormat.serialize(:a).should eq Bytes[97, 0]
    end
  end

  describe "compiles when an object has two enum ivars" do
    assert_byte_format_serialization(ObjWithEnum.new, Bytes[1, 0, 0, 0, 0, 1, 0, 0, 0])
  end
end
