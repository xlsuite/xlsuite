require File.dirname(__FILE__) + "/../test_helper"

class StepRunnerFutureTest < Test::Unit::TestCase
  setup do
    @account = accounts(:wpul)
    @runner = StepRunnerFuture.new(:account => @account, :system => true)
  end

  should "tell Step to return the next runnable steps" do
    Step.expects(:find_next_runnable_steps).returns([])
    @runner.run
  end

  should "call #complete!" do
    @runner.expects(:complete!)
    @runner.run
  end

  should "schedule a MethodCallbackFuture per Step returned from #find_next_runnable_steps" do
    Step.expects(:find_next_runnable_steps).returns([step0 = mock("step0")])
    MethodCallbackFuture.expects(:create!).with(:model => step0, :method => :run, :system => true)
    @runner.run
  end
end
