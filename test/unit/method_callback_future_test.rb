require File.dirname(__FILE__) + "/../test_helper"

class MethodCallbackFutureTest < Test::Unit::TestCase
  setup do
    @account = accounts(:wpul)
  end

  context "A method callback future instantiated with a single model" do
    setup do
      @future = MethodCallbackFuture.new(:model => parties(:bob), :method => :callback_method,
          :owner => parties(:bob), :account => @account)
      @future.save!
      @future.reload
    end

    should "save the model's ID in the :ids argument" do
      assert_equal [parties(:bob).id], @future.args[:ids]
    end

    should "save the model's class name in the :model argument" do
      assert_equal parties(:bob).class.name, @future.args[:class_name]
    end

    should "save the model's callback method in :method" do
      assert_equal "callback_method", @future.args[:method]
    end
  end

  context "A method callback future instantiated with many models" do
    setup do
      @future = MethodCallbackFuture.new(:models => [parties(:bob), parties(:mary)],
          :method => :set_effective_permissions, :account => @account)
      @future.save!
      @future.reload
    end

    should "save the model's IDs in the :ids argument" do
      assert_equal [parties(:bob).id, parties(:mary).id], @future.args[:ids]
    end

    should "save the model's class name in the :model argument" do
      assert_equal parties(:bob).class.name, @future.args[:class_name]
    end

    should "save the model's callback method in :method" do
      assert_equal "set_effective_permissions", @future.args[:method]
    end

    context "being executed" do
      setup do
        Party.stubs(:find).returns([@bob = stub("bob"), @mary = stub("mary")])
        @bob.stubs(:set_effective_permissions)
        @mary.stubs(:set_effective_permissions)
      end

      should "find the models" do
        Party.expects(:find).with([parties(:bob).id, parties(:mary).id]).returns([])
        @future.execute
      end

      should "call #set_effective_permissions on all models" do
        @bob.expects(:set_effective_permissions)
        @mary.expects(:set_effective_permissions)
        @future.execute
      end

      should "be completed" do
        @future.execute
        assert @future.reload.completed?
      end
    end
  end

  context "A method callback future with the :repeat_until_true option set to true" do
    setup do
      @future = MethodCallbackFuture.create!(:repeat_until_true => true, :model => parties(:mary),
          :method => :some_method_that_returns_true_or_something_else, :account => parties(:mary).account)
    end

    should "NOT be completed when the called method returns nil" do
      @future.stubs(:models).returns([party = stub("party")])
      party.stubs(:some_method_that_returns_true_or_something_else).returns(nil)
      @future.reload.execute
      deny @future.reload.completed?
    end

    should "NOT be started when the called method returns nil" do
      @future.stubs(:models).returns([party = stub("party")])
      party.stubs(:some_method_that_returns_true_or_something_else).returns(nil)
      @future.reload.execute
      assert_nil @future.reload.started_at
    end

    should "be completed when the called method returns true" do
      @future.stubs(:models).returns([party = stub("party")])
      party.stubs(:some_method_that_returns_true_or_something_else).returns(true)
      @future.reload.execute
      assert @future.reload.completed?
    end
  end

  context "A method callback future instantiated with many disparate models" do
    setup do
      @future = MethodCallbackFuture.new(:models => [parties(:bob), products(:fish)],
          :method => :set_effective_permissions, :account => @account)
      @future.valid?
    end

    should "not be valid" do
      deny @future.valid?
    end

    should "flag the :models attribute as invalid" do
      assert_equal "must contain a single type of object, found Party and Product", @future.errors.on(:models)
    end
  end
end
