require File.dirname(__FILE__) + '/../test_helper'

class AssigneeTest < Test::Unit::TestCase
  setup do
    @account = accounts(:wpul)
  end

  context "ModelBuilder" do
    should "return a valid Assignee" do
      assignee = build_assignee
      assert assignee.valid?, assignee.errors.full_messages.to_sentence
    end
  end

  context "An existing assignee" do
    setup do
      @assignee = create_assignee
    end

    should "belong to a task" do
      assert_kind_of Task, @assignee.task
    end
  end
end
