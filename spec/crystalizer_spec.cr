require "spec"
require "../src/crystalizer"

module Crystalizer
  def self.test_each_ivar(object : O, &) forall O
    each_ivar(object) do |key, obj, var|
      yield key, obj, var
    end
  end
end

private abstract struct Abstract
  @a = 0
end

private struct Struct < Abstract
  @b = 1
end

describe Crystalizer do
  describe "each_ivar" do
    it "yields also ivars from parent type" do
      ary = Array({String, Int32}).new
      Crystalizer.test_each_ivar Struct.new do |key, obj|
        ary << {key, obj}
      end
      ary.should eq [{"a", 0}, {"b", 1}]
    end
  end
end
