require File.dirname(__FILE__) + "/../../test_helper"

class SendMassMailActionTest < Test::Unit::TestCase
  setup do
    @account = accounts(:wpul)
    @step = @account.steps.create!(:model_class_name => "Party")
    
    @action = SendMassMailAction.new
    @action.sender = parties(:mary)
    @action.mail_type = Email::ValidMailTypes.first

    @template = @action.template = mock("template")
    @template.stubs(:subject).returns("SellFM Price Sheet")
    @template.stubs(:body).returns("Get the price sheet from this URL: /.../")
  end
  
  context "A send mass mail action whose step trigger lines" do
    context "contains tagged_all 'abc, def'" do
      setup do
        @step.lines = [ReportEqualsLine.new(:field => "tagged_all", :value => "abc, def")]
        @step.save!

        @email = @action.run_against(parties(:bob), {:account => @account, :step_id => @step.id})
      end
      
      should "has two inactive TagListBuilder" do
        builders = @email.tos.select{|e| e.recipient_builder_type == TagListBuilder.name }
        assert_equal 2, builders.size
        builders.each do |builder|
          assert builder.inactive?
        end
        assert_equal ["abc", "def"], builders.map(&:tag_syntax)
      end  
    end
    
    context "contains group_label" do
      setup do
        @step.lines = [ReportEqualsLine.new(:field => "group_label", :value => groups(:billing))]
        @step.save!

        @email = @action.run_against(parties(:bob), {:account => @account, :step_id => @step.id})
      end
    
      should "has an inactive GroupListBuilder" do
        builders = @email.tos.select{|e| e.recipient_builder_type == GroupListBuilder.name}
        assert_equal 1, builders.size
        builders.each do |builder|
          assert builder.inactive?
        end
        assert_equal groups(:billing).id, builders.first.recipient_builder_id
      end
    end
  end
  
end
