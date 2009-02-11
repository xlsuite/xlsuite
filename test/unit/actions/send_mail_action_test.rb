require File.dirname(__FILE__) + "/../../test_helper"

class SendMailActionTest < Test::Unit::TestCase
  setup do
    @account = accounts(:wpul)
    @action = SendMailAction.new
    @template = @action.template = mock("template")
    @sender = @action.sender = mock("sender")
  end

  should "return the same template as was set" do
    assert_same @template, @action.template
  end

  should "return the same sender as was set" do
    assert_equal @sender, @action.sender
  end

  context "A send mail action with a template and sender" do
    setup do
      @template.stubs(:label).returns("email template label")
      @sender.stubs(:name).returns(stub_everything("name", :to_s => "party name"))
      @sender.stubs(:display_name).returns(stub_everything("name", :to_s => "party name"))
    end

    should "have 'Send mail' in it's description" do
      assert_include "Send mail", @action.description
    end

    should "have the template's label in it's description" do
      assert_include @template.label, @action.description
    end

    should "have the sender's name in it's description" do
      assert_include @sender.name.to_s, @action.description
    end

    context "when calling \#run_against" do
      setup do
        @template.stubs(:subject).returns("SellFM Price Sheet")
        @template.stubs(:body).returns("Get the price sheet from this URL: /.../")
        @action.sender = parties(:mary)
        @action.mail_type = Email::ValidMailTypes.first
        @email = @action.run_against(parties(:bob), :account => @account)
      end

      should "send the mail from Mary" do
        assert_equal parties(:mary), @email.sender.party
      end

      should "send the mail to bob" do
        assert_equal [parties(:bob)], @email.tos.map(&:party)
      end

      should "have copied the template's subject" do
        assert_equal @template.subject, @email.subject
      end

      should "have copied the template's body" do
        assert_equal @template.body, @email.body
      end
    end
  end
end
