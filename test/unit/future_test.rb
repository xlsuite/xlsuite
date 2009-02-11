require File.dirname(__FILE__) + "/../test_helper"

class FutureTest < Test::Unit::TestCase
  setup do
    @account = accounts(:wpul)
  end

  should "defaults to an empty Hash" do
    assert_equal Hash.new, Future.new.args
  end

  context "A saved Future with arguments" do
    setup do
      @future = Future.new
      @future.args[:value1] = "abc"
      @future.args[:value2] = "def"
      @future.save(false)
    end

    should "reload with the stored arguments" do
      expected = {:value1 => "abc", :value2 => "def"}
      assert_equal expected, @future.reload.args
    end

    should "find with the stored arguments" do
      expected = {:value1 => "abc", :value2 => "def"}
      assert_equal expected, Future.find(@future.id).args
    end
  end
end
