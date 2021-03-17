require "../../src/deserializer/non_self_describing_object"
require "../../src/deserializer/self_describing_object"

struct Properties
  property str : String = "Hello"
  property enabled : Bool = false
end

struct Strukt
  def initialize(@num : Int32)
  end
end

abstract struct Abstract
  abstract def num : Int32
end

struct S0 < Abstract
  getter num : Int32 = 0
end

struct S1 < Abstract
  getter num : Int32 = 1
end

describe Crystalizer::Deserializer::Object do
  describe Crystalizer::Deserializer::SelfDescribingObject do
    it "creates an object with default values" do
      obj = Crystalizer::Deserializer::SelfDescribingObject.new Properties
      obj.object_instance.should eq Properties.new
    end

    it "sets an instance variable" do
      obj = Crystalizer::Deserializer::SelfDescribingObject.new Strukt
      obj.set_ivar "num" { 123 }
      obj.object_instance.should eq Strukt.new 123
    end

    it "raises on setting a unknown key" do
      expect_raises Crystalizer::Deserializer::Object::Error,
        message: "Unknown field in Strukt matching the given string: unknown_var" do
        obj = Crystalizer::Deserializer::SelfDescribingObject.new Strukt
        obj.set_ivar "unknown_var" { 0 }
      end
    end

    it "raises on unset instance variable" do
      expect_raises Crystalizer::Deserializer::Object::Error,
        message: "Missing instance variable value in Strukt: num" do
        Crystalizer::Deserializer::SelfDescribingObject.new(Strukt).object_instance
      end
    end

    it "deserializes abstract types" do
      {S0, S1}.each_with_index do |t, i|
        Crystalizer::Deserializer::SelfDescribingObject.new(t).object_instance.num.should eq i
      end
    end
  end

  describe Crystalizer::Deserializer::NonSelfDescribingObject do
    it "sets an instance variable" do
      obj = Crystalizer::Deserializer::NonSelfDescribingObject.new Strukt
      obj.set_each_ivar { 123 }
      obj.object_instance.should eq Strukt.new 123
    end

    it "raises on non #set_each_ivar not called" do
      expect_raises Crystalizer::Deserializer::Object::Error,
        message: "#set_each_ivar not previously called: no instance variable set." do
        obj = Crystalizer::Deserializer::NonSelfDescribingObject.new Properties
        obj.object_instance
      end
    end

    it "deserializes abstract types" do
      {S0, S1}.each_with_index do |t, i|
        Crystalizer::Deserializer::SelfDescribingObject.new(t).object_instance.num.should eq i
      end
    end
  end
end
