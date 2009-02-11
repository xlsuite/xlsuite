require File.dirname(__FILE__) + '/../test_helper'

class TaskTest < Test::Unit::TestCase
  setup do
    @account = accounts(:wpul)
  end

  context "ModelBuilder" do
    should "return a valid Task" do
      task = build_task
      assert task.valid?, task.errors.full_messages.to_sentence
    end
  end

  context "An existing task" do
    setup do
      @task = create_task
    end

    should "do nothing when no Action defined" do
      assert_nothing_raised do
        @task.run(mock("a model"))
      end
    end

    should "call each action's \#run_against method with the models" do
      @task.stubs(:actions).returns([action0 = mock("action0")])
      action0.expects(:run_against).with(models = [:model0])
      @task.run(models)
    end

    should "do nothing when assignees present" do
      @task.stubs(:actions).returns([action0 = mock("action0")])
      action0.expects(:run_against).never
      @task.assignees << Assignee.new(:account => accounts(:wpul))
      @task.run([parties(:bob)])
    end

    should "have many assignees" do
      assert_nothing_raised do
        @task.assignees.create!(:party => parties(:bob))
      end
    end

    should "belong to a step" do
      assert_kind_of Step, @task.step
    end

    should "have an empty actions array on initial read" do
      assert_equal [], @task.actions
    end

    should "serialize the actions to the DB" do
      @task.actions << AddTagAction.new(:tag_name => "abc")
      @task.save!
      assert_equal 1, @task.reload.actions.length
    end
  end
end
