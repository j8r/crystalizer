require "../src/field.cr"
require "../src/type"
require "../src/format"

struct Point
  getter x : Int32
  @[Crystalizer::Field(key: "Y")]
  getter y : String = "a"

  def initialize(@x)
  end
end

class Obj
  getter ary

  def initialize(@ary : Array(String))
  end

  def ==(other : self)
    @ary == other.ary
  end
end

class Nested
  getter str : String

  def initialize(@str)
  end

  def ==(other : self)
    @str == other.str
  end
end

class Parent
  getter str : String

  getter nested : Nested

  def initialize(@str, @nested)
  end

  def ==(other : self)
    @str == other.str && @nested == other.nested
  end
end

enum Enu
  A
  B
end

enum Other
  A
  B
end

record ObjWithEnum, i = 1_u8, enu1 = Enu::A, other = Other::B

struct TestCustomTypeSerialization
  include Crystalizer::Type

  def initialize(@i : Int32 = 1)
  end

  def self.deserialize(deserializer : Crystalizer::Deserializer)
    new deserializer.deserialize to: Int32
  end

  def serialize(serializer : Crystalizer::Serializer) : Nil
    serializer.serialize @i
  end
end

struct CustomSub
  @str = "abc"
  @custom = TestCustomTypeSerialization.new
end
