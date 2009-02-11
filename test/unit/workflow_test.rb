require File.dirname(__FILE__) + '/../test_helper'

class WorkflowTest < Test::Unit::TestCase
  setup do
    @account = accounts(:wpul)
  end

  context "ModelBuilder" do
    should "return a valid Workflow" do
      workflow = build_workflow
      assert workflow.valid?, workflow.errors.full_messages.to_sentence
    end
  end

  context "An existing workflow" do
    setup do
      @workflow = create_workflow
    end

    should "have many steps" do
      assert_nothing_raised do
        @workflow.steps.create!(:title => "Day 1", :model_class => Party)
      end
    end
    
    context "with a step" do
      setup do
        @workflow.steps.create!(:title => "Day 1", :model_class => Party)
      end
      
      should "destroy the step when the workflow is destroyed" do
        assert_difference Workflow, :count, -1 do
          assert_difference Step, :count, -1 do
            @workflow.destroy            
          end
        end
      end
      
    end
  end
end
