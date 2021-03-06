require "../src/field.cr"

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
