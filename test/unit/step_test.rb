require File.dirname(__FILE__) + '/../test_helper'

class StepTest < Test::Unit::TestCase
  setup do
    @account = accounts(:wpul)
  end

  context "ModelBuilder" do
    should "return a valid Step" do
      step = build_step
      assert step.valid?, step.errors.full_messages.to_sentence
    end
  end

  context "An existing step" do
    setup do
      @step = create_step
    end

    should "call \#step when calling \#step!" do
      @step.expects(:run)
      @step.run!
    end
    
    should "get the list of models when being \#run" do
      @step.expects(:models).returns([])
      @step.run
    end

    should "call \#run on each Task with the list of models" do
      @step.stubs(:models).returns([:model0, :model1])
      @step.stubs(:tasks).returns([task0 = mock("task0")])
      task0.expects(:run).with(@step.models)
      @step.run
    end

    should "return an empty Array for \#lines when not accessed" do
      assert_equal [], @step.lines
    end

    should "have a \#line= accessor" do
      @step.lines = [ReportContainsLine.new(:field => "name", :value => "can of worms")]
    end

    should "save lines to the database" do
      lines = [ReportContainsLine.new(:field => "name", :value => "can of worms")]
      @step.lines = lines
      @step.save!
      assert_equal lines, Step.find(@step.id).lines
    end

    should "have many tasks" do
      assert_nothing_raised do
        @step.tasks.create!
      end
    end

    should "belong to a workflow" do
      assert_kind_of Workflow, @step.workflow
    end

    context "with a task" do
      setup do
        @step.tasks.create!
      end
      
      should "destroy the task when the step is destroyed" do
        assert_difference Step, :count, -1 do
          assert_difference Task, :count, -1 do
            @step.destroy            
          end
        end
      end
    end

    context "with 'party tagged newsletter, not tagged newsletter-week2' as a query" do
      setup do
        @step.model_class = Party
        @step.lines = [
          ReportEqualsLine.new(:field => "tagged_all", :value => "newsletter"),
          ReportEqualsLine.new(:field => "tagged_all", :value => "newsletter-week2", :excluded => true)
        ]
        @step.save!

        @mary = parties(:mary)
      end

      context "when Mary is tagged newsletter" do
        setup do
          @mary.tag("newsletter")
        end

        should "find Mary by tag" do
          assert_include parties(:mary), accounts(:wpul).parties.find_tagged_with(:all => "newsletter")
        end

        should "find Mary through \#models" do
          assert_include parties(:mary), @step.models
        end

        context "when Mary is also tagged newsletter-week2" do
          setup do
            @mary.tag("newsletter-week2")
          end

          should "NOT find Mary through \#models" do
            assert_not_include parties(:mary), @step.models
          end
        end
      end
    end
  end
end
