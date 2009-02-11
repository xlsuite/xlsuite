require File.dirname(__FILE__) + "/../test_helper"

class SmalltalkTest < Test::Unit::TestCase
  setup do
    @block = Proc.new { true }
  end

  context "The nil object" do
    should "yield when calling #if_nil on it" do
      assert nil.if_nil(&@block)
    end

    should "return nil upon returning from #if_not_nil" do
      assert_nil nil.if_not_nil(&@block)
    end

    should "not yield when calling #if_not_nil on it" do
      deny nil.if_not_nil(&@block)
    end
  end

  context "A non nil object" do
    should "not yield when calling #if_nil on it" do
      assert_equal "", "".if_nil(&@block)
    end

    should "yield when calling #if_not_nil on it" do
      assert "".if_not_nil(&@block)
    end

    should "pass itself to #if_not_nil" do
      obj = "abc"
      assert_same obj, obj.if_not_nil {|o| o}
    end
  end
end
