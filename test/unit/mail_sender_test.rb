require File.dirname(__FILE__) + "/../test_helper"

class MailSenderTest < Test::Unit::TestCase
  context "A runnable MailSender" do
    setup do
      @sender = MailSender.create!(:system => true)
    end

    context "with one ready E-Mail" do
      setup do
        @mail = mock("mail")
        Email.stubs(:pluck_next_ready_mails).returns([@mail])
      end

      should "schedule a SYSTEM MethodCallbackFuture" do
        MethodCallbackFuture.expects(:create!).with(has_entry(:system => true))
        @sender.run
      end

      should "schedule a MethodCallbackFuture that calls #send!" do
        MethodCallbackFuture.expects(:create!).with(has_entry(:method => :send!))
        @sender.run
      end

      should "schedule a MethodCallbackFuture on the E-Mail" do
        MethodCallbackFuture.expects(:create!).with(has_entry(:model => @mail))
        @sender.run
      end
    end

    context "with no ready E-Mails" do
      setup do
        Email.stubs(:pluck_next_ready_mails).returns([])
      end

      should "NOT instantiate a MethodCallbackFuture" do
        MethodCallbackFuture.expects(:create!).never
        @sender.run
      end

      should "complete itself" do
        @sender.run
        assert @sender.completed?
      end

      should "call #pluck_next_ready_mails" do
        Email.expects(:pluck_next_ready_mails).returns([])
        @sender.run
      end
    end
  end
end
