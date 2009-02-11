require File.dirname(__FILE__) + '/../test_helper'
require 'mail_reader'

class MailReaderTest < Test::Unit::TestCase
  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = @mails = []

    @account = Account.find(:first)
    @bob = parties(:bob)
    @mary = parties(:mary)

    @mail = TMail::Mail.new
    @mail.set_content_type "text", "plain", {"charset" => 'ISO-8859-1'}

    @parties = Party.count
    @emails = Email.count
    @recipients = Recipient.count
  end

  context "A mail sent from Bob to Mary, with subject 'a nice summer', and body 'interesting place'" do
    setup do
      @mail.from = @bob.main_email.address
      @mail.to = @mary.main_email.address
      @mail.subject = "a nice summer"
      @mail.body = "interesting place"
      @mail.message_id = '<uf9asjdf093j2@party.goer.com>'
      @mail.date = Time.now
    end

    context "when received by the system" do
      setup do
        MailReader.account = @account
        MailReader.user = @mary
        @email = MailReader.receive(@mail.encoded)
        @email.reload
      end

      should "add an Email to the system" do
        assert_equal @emails + 1, Email.count
      end

      should "tag the recipient with 'inbox'" do
        recipient = @email.tos.first
        assert_equal 'inbox', recipient.tag_list['inbox'],
            "Email recipient not tagged inbox: #{recipient.tag_list}"
      end

      should "set the mail's sender to Bob" do
        assert_equal @bob.name.to_s, @email.sender.party.name.to_s
      end

      should "set the mail's To recipients to Mary" do
        assert_equal [@mary], @email.tos.map(&:party)
      end

      should "set the mail's subject to 'a nice summer'" do
        assert_equal "a nice summer", @email.subject
      end

      should "set the mail's body to 'interesting place'" do
        assert_equal "interesting place", @email.body
      end

      should "set received_at to now" do
        assert_include @email.received_at, 1.second.ago .. 1.second.from_now
      end
    end
  end
  
  context "A mail from Mr Incredible to Dash, with subject 'run home now' and body 'your mother thus spoke'" do
    setup do
      @mail.from = 'Mr Incredible <bob@theparrs.name>'
      @mail.to = 'Dash <dashiel@theparrs.name>'
      @mail.subject = 'Run home now !!!'
      @mail.body = 'Your mother thus spoke'
      @mail.message_id = '<uf9asjdf093j2@party.goer.com>'
    end

    context "when received by the system" do
      setup do
        MailReader.account = Account.find(:first)
        MailReader.user = parties(:mary)
        @email = MailReader.receive(@mail.encoded)
        @email.reload
      end

      should "add Mr Incredible and Dash to the system" do
        assert_equal 2, Party.count - @parties
      end

      should "make the sender's party name 'Mr Incredible'" do
        assert_equal "Mr Incredible", @email.sender.party.last_name
      end

      should "make the recipient's party name 'Dash'" do
        assert_equal "Dash", @email.tos.first.party.last_name
      end
    end
  end

  context "A mail from Mr Incredible to Dash, Violet and Helen" do
    setup do
      @mail.from = 'Mr Incredible <bob@theparrs.name>'
      @mail.to = 'Dash <dashiel@theparrs.name>, Violet <violet@theparrs.name>, Helen <helen@theparrs.net>'
      @mail.subject = 'Run home now !!!'
      @mail.body = 'Your mother thus spoke'
      @mail.message_id = '<uf9asjdf093j2@party.goer.com>'
    end
    
    context "when received by the system" do
      setup do
        MailReader.account = Account.find(:first)
        MailReader.user = parties(:mary)
        @email = MailReader.receive(@mail.encoded)
        @email.reload
      end

      should "have 3 To recipients" do
        assert_equal 3, @email.tos.size
      end
    end
  end

  context "A mail from Mr Incredible to Dash, Cc'd to Violet and Bcc'd to Helen" do
    setup do
      @mail.from = 'Mr Incredible <bob@theparrs.name>'
      @mail.to = 'Dash <dashiel@theparrs.name>'
      @mail.cc = 'Violet <violet@theparrs.name>'
      @mail.bcc = 'Helen <helen@theparrs.net>'
      @mail.subject = 'Run home now !!!'
      @mail.body = 'Your mother thus spoke'
      @mail.message_id = '<uf9asjdf093j2@party.goer.com>'
    end

    context "when received by the system" do
      setup do
        MailReader.account = Account.find(:first)
        MailReader.user = parties(:mary)
        @email = MailReader.receive(@mail.encoded)
        @email.reload
      end

      should "have 3 recipients total (To + Cc + Bcc)" do
        assert_equal [1, 1, 1], [@email.tos.size, @email.ccs.size, @email.bccs.size]
      end

      should "have Dash in the To field" do
        assert_equal "Dash", @email.tos.first.party.name.last
      end

      should "have Violet in the Cc field" do
        assert_equal "Violet", @email.ccs.first.party.name.last
      end

      should "have Helen in the Bcc field" do
        assert_equal "Helen", @email.bccs.first.party.name.last
      end
    end
  end

  context "A previously received mail" do
    setup do
      @mail.from = parties(:bob).main_email
      @mail.to = parties(:mary).main_email
      @mail.subject = 'Run home now !!!'
      @mail.body = 'Your mother thus spoke'
      @mail.message_id = '<uf9asjdf093j2@party.goer.com>'

      MailReader.account = Account.find(:first)
      MailReader.user = parties(:mary)
      @email0 = MailReader.receive(@mail.encoded)
    end

    context "that we receive again" do
      setup do
        MailReader.account = Account.find(:first)
        MailReader.user = parties(:mary)
        @email1 = MailReader.receive(@mail.encoded)
      end

      should "create only one instance in the databse" do
        assert_equal 1, Email.count - @emails
      end

      should "return the previously received email" do
        assert_equal @email0.id, @email1.id
      end
    end
  end

  context "A mail with multipart text and HTML" do
    setup do
      @mail = TMail::Mail.load(File.join(RAILS_ROOT, 'test', 'fixtures', 'emails', 'mail-with-text-and-html.eml'))
    end
    
    context "when it is received" do
      setup do
        MailReader.account = Account.find(:first)
        MailReader.user = parties(:mary)
        @email = MailReader.receive(@mail.encoded)
        @email.reload
      end

      should "only copy the plain text content" do
        assert_equal 'plain text', @email.body.strip
      end
    end
  end

  context "A mail with multipart HTML only" do
    setup do
      @mail = TMail::Mail.load(File.join(RAILS_ROOT, "test", "fixtures", "emails", "mail-with-html-only.eml"))
    end

    context "when it is received" do
      setup do
        MailReader.account = Account.find(:first)
        MailReader.user = parties(:mary)
        @email = MailReader.receive(@mail.encoded)
        @email.reload
      end

      should "keep the plain text version of the text" do
        assert_equal "html text", @email.body.strip
      end
    end
  end

  context "A mail with a multipart attachment" do
    setup do
      @mail = TMail::Mail.load(File.join(RAILS_ROOT, "test", "fixtures", "emails", "mail-with-attachment.eml"))
    end

    context "when it is received" do
      setup do
        MailReader.account = Account.find(:first)
        MailReader.user = parties(:mary)
        @email = MailReader.receive(@mail.encoded)
        @email.reload
        @attachment = @email.attachments.first
      end

      should "add one attachment to the Email" do
        assert_equal 1, @email.attachments.count
      end

      should "set the attachment's filename to the filename" do
        assert_equal "teksol-signature.txt", @attachment.filename
      end

      should "set the attachment's content type to the original content type" do
        assert_equal "text/plain", @attachment.content_type
      end

      should "set the attachment's size to the original size" do
        # Because of encoding differences between PC/Linux (and because this
        # is a plain text attachment), we have to assert against both sizes
        assert_include @attachment.size, [135, 139]
      end

      should "set the mail's body to the original body" do
        assert_equal "small attachment", @email.body.strip
      end

      should "set the attachment's text to the original body" do
        assert_equal @mail.parts.detect {|part| part.disposition_param("filename")}.body.strip, @attachment.current_data.strip
      end
    end
  end
end
