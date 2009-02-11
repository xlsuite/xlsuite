require File.dirname(__FILE__) + "/../test_helper"
require "mass_mailer"

class MassMailerTest < Test::Unit::TestCase
  def setup
    ActionMailer::Base.deliveries = @mails = []
    @account = Account.find(:first)
    @bob = parties(:bob)
    @john = parties(:john)
    @peter = parties(:peter)
    @mary = parties(:mary)
  end

  context "A released mail" do
    setup do
      @email = @account.emails.create!(:sender => @bob, :tos => "#{@mary.main_email.address}", :subject => "good day", :body => "/subj.")
      @email.release!
    end

    context "with outline attachments" do
      setup do
        @email.update_attribute(:inline_attachments, false)
        @asset = @account.assets.create!(:uploaded_data => uploaded_file("large.jpg"), :owner => @email.sender.party)
        @email.assets << @asset

        MassMailer.deliver_mailing(@email.reload)
        @sent_mail = @mails.first
      end

      should "NOT attach a file to the E-Mail" do
        assert_equal [], @sent_mail.attachments
      end

      should "have appended the asset's URL to the document" do
        domain = @email.account.domain_name
        assert_include "http://#{domain}/admin/assets/#{@asset.id}/download", @sent_mail.body
      end
    end

    context "with inline attachments" do
      setup do
        @email.update_attribute(:inline_attachments, true)
        @asset = @account.assets.create!(:uploaded_data => uploaded_file("large.jpg"), :owner => @email.sender.party)
        @email.assets << @asset
        MassMailer.deliver_mailing(@email.reload)
        @sent_mail = @mails.first
      end

      should "send one mail" do
        assert_equal 1, @mails.size
      end

      should "set the sent mail's subject" do
        assert_equal @email.subject, @sent_mail.subject
      end

      should "set the sent mail's body" do
        assert_include "Attachment: large.jpg\n" + @email.body, @sent_mail.body
      end

      should "set the sent mail's FROM" do
        assert_equal [@email.sender.to_formatted_s.gsub('"', '')], @sent_mail.from_addrs.map(&:to_s)
      end

      should "set the sent mail's TO" do
        assert_equal @email.tos.map{|to|to.to_formatted_s.gsub('"', '')}, @sent_mail.to_addrs.map(&:to_s)
      end

      should "set leave the sent mail's CC field blank" do
        assert_nil @sent_mail.cc_addrs
      end

      should "set leave the sent mail's BCC field blank" do
        assert_nil @sent_mail.bcc_addrs
      end

      should "add one attachment" do
        assert_equal 1, @sent_mail.attachments.size
      end
    end
  end
end
