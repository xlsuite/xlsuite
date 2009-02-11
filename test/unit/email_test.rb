require File.dirname(__FILE__) + '/../test_helper'

class EmailTest < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
    @email = Email.new(:account => @account, :subject => "love", :body => "static body", :released_at => Time.now.utc)
    @email.sender = parties(:bob)
    assert @email.valid?, "E-mail is invalid"
  end

  context "A mass email" do
    setup do
      @mass_email = @account.emails.create!(:mass_mail => true, :body => "This is a body", :subject => "Subject",
                                            :sender => parties(:bob), :account => @account, :current_user => parties(:bob),
                                            :tos => "tag=staff, Staff Members, Billing, #{parties(:bob).main_email.to_s}")
      @mass_email.reload
    end

    should "create to recipients, one per tos" do
      assert_equal 4, @mass_email.tos.size, @mass_email.tos.map(&:attributes).map(&:inspect).inspect
      assert_equal ["GroupListBuilder", "GroupListBuilder", "TagListBuilder", "PartyListBuilder"].sort,
        @mass_email.tos.map(&:recipient_builder_type).sort
    end

    should "not have created bccs" do
      assert_equal 0, @mass_email.bccs.size
    end

    should "not have created ccs" do
      assert_equal 0, @mass_email.ccs.size
    end

    should "send one per mass recipient" do
      ActionMailer::Base.deliveries = mails = []
      @mass_email.release
      @mass_email.send!
      assert_equal 4, @mass_email.mass_recipients.count
      assert_not_nil @mass_email.reload.sent_at
    end
  end

  context "A mail with no recipients" do
    should "return a non-delivery to the sender" do
      @email.save!
      @email.expects(:return_non_delivery_to_sender!)
      @email.send!
    end
  end

  context "A mail where the server raises a Net::SMTPError" do
    setup do
      @email.save!
      @email.tos = parties(:mary).main_email.address
      @email.save!
      MassMailer.expects(:deliver_mailing).with(@email).raises(Net::SMTPSyntaxError)
    end

    should "reschedule the mail one hour from now when the error limit has not been reached" do
      @email.error_count = 1
      @email.expects(:reschedule!).with(1.hour.from_now)
      @email.send!
    end

    should "return a non-delivery report to the sender when the error limit has been reached" do
      @email.error_count = 5
      @email.expects(:return_non_delivery_to_sender!)
      @email.send!
    end
  end

  context "A new mail with no recipients" do
    should "accept an Array of E-Mail addresses when building recipients" do
      @email.tos = %w(john@xlsuite.com peter@xlsuite.com)
      @email.save(false)
      assert_equal %w(<john@xlsuite.com> <peter@xlsuite.com>).sort, @email.tos.map(&:to_formatted_s).sort
    end

    should "accept a String of E-Mail addresses separated by newlines when building recipients" do
      @email.tos = "john@xlsuite.com\npeter@xlsuite.com"
      @email.save(false)
      assert_equal %w(<john@xlsuite.com> <peter@xlsuite.com>).sort, @email.tos.map(&:to_formatted_s).sort
    end

    should "accept a String of E-Mail addresses separated by commas when building recipients" do
      @email.tos = "john@xlsuite.com, peter@xlsuite.com"
      @email.save(false)
      assert_equal %w(<john@xlsuite.com> <peter@xlsuite.com>).sort, @email.tos.map(&:to_formatted_s).sort
    end

    should "accept an array of String E-Mail addresses separated by commas and newlines" do
      @email.tos = ["john@xlsuite.com, peter@xlsuite.com\nsarah@xlsuite.com"]
      @email.save(false)
      assert_equal %w(<john@xlsuite.com> <peter@xlsuite.com> <sarah@xlsuite.com>).sort, @email.tos.map(&:to_formatted_s).sort
    end

    should "accept an Array of EmailContactRoutes" do
      routes = @account.email_contact_routes.find(:all)
      @email.tos = routes
      @email.save! # Must save or #tos will return 0 (because no DB objects were created
      assert_equal routes.size, @email.tos.size
    end

    should "accept an Array of Parties" do
      parties = @account.parties.find(:all)
      @email.tos = parties
      @email.save! # Must save or #tos will return 0 (because no DB objects were created
      assert_equal parties.size, @email.tos.size
    end

    should "accept a single EmailContactRoute" do
      route = @account.email_contact_routes.find(:first)
      @email.tos = route
      @email.save! # Must save or #tos will return 0 (because no DB objects were created
      assert_equal [route.to_formatted_s], @email.tos.map(&:to_formatted_s)
    end

    should "accept a single Party" do
      party = @account.parties.find(:first)
      @email.tos = party
      @email.save! # Must save or #tos will return 0 (because no DB objects were created
      assert_equal party, @email.tos.first.party
    end
  end
end

class BuildRecipientsEmailTest < Test::Unit::TestCase
  def setup
    @email = parties(:bob).account.emails.build(:current_user => parties(:bob))
    @sender = Sender.new(:party => parties(:bob), :name => parties(:bob).name.to_forward_s, 
        :address => parties(:bob).main_email.address)
    @email.attributes = {:sender => @sender, :body => "body", :subject => "subject"}
  end
  
  def test_with_one_recipient
    @email.tos = parties(:mary).main_email.address
    error_messages = []
    @email.tos.each do |e|
      error_messages += e.errors.full_messages
    end
    error_messages.flatten!
    assert error_messages.blank?, error_messages
    assert @email.valid?, @email.errors.full_messages
  end
  
  def test_with_two_recipients
    @email.tos = parties(:mary).main_email.address, parties(:john).main_email.address
    error_messages = []
    @email.tos.each do |e|
      error_messages += e.errors.full_messages
    end
    error_messages.flatten!
    assert error_messages.blank?, error_messages
    assert @email.valid?, @email.errors.full_messages
    assert_difference Email, :count, 1 do
      assert_difference Recipient, :count, 3 do # one Sender, two ToRecipient
        assert @email.save
        @email.tos.each do |recipient|
          assert_equal recipient.email_id, @email.id
        end
      end
    end
  end
  
  def test_with_one_valid_one_invalid
    @email.tos = parties(:mary).main_email.address, 'this should be invalid'
    error_messages = []
    @email.tos.each do |e|
      error_messages += e.errors.full_messages
    end
    error_messages.flatten!
    assert error_messages.blank?, error_messages
    assert @email.valid?, @email.errors.full_messages
  end
end

class UnreleasedUnscheduledEmailTest < Test::Unit::TestCase
  def setup
    @now = Time.local(2006, 2, 1, 0, 0, 0)
    @email = parties(:bob).account.emails.build(:current_user => parties(:bob))
    @sender = Sender.new(:party => parties(:bob), 
        :name => parties(:bob).name.to_forward_s, 
        :address => parties(:bob).main_email.email_address, :account => @email.account)
    @email.attributes = {:subject => 'test', :body => 'body text', 
        :tos => parties(:bob).main_email.email_address, :sender => @sender}
  end

  def test_account_asssociation
    assert_equal Account.find(:first), @email.account
  end
  
  def test_reports_as_draft
    assert @email.draft?
  end

  def test_status_is_draft
    assert_equal :draft, @email.status
  end
end

class ReleasedUnscheduledEmailTest < Test::Unit::TestCase
  def setup
    @now = Time.local(2006, 2, 1, 0, 0, 0)
    @email = parties(:bob).account.emails.build(:current_user => parties(:bob))
    @sender = Sender.new(:party => parties(:bob), 
        :name => parties(:bob).name.to_forward_s, 
        :address => parties(:bob).main_email.email_address, :account => @email.account)
    @email.attributes = {:subject => 'test', :body => 'body text', 
        :tos => parties(:bob).main_email.email_address, :sender => @sender}
    @email.release!(@now)
  end

  def test_status_is_ready
    assert_equal :ready, @email.status
  end
end

class UnreleasedScheduledEmailTest < Test::Unit::TestCase
  def setup
    @now = Time.local(2006, 2, 1, 0, 0, 0)
    @email = parties(:bob).account.emails.build(:current_user => parties(:bob))
    @sender = Sender.new(:party => parties(:bob), 
        :name => parties(:bob).name.to_forward_s, 
        :address => parties(:bob).main_email.email_address, :account => @email.account)
    @email.attributes = {:subject => 'test', :body => 'body text', 
        :tos => parties(:bob).main_email.email_address, :sender => @sender}
    @email.update_attribute(:scheduled_at, @now)
  end

  def test_status_is_unreleased
    assert_equal :unreleased, @email.status
  end
end

class ReleasedScheduledAndReleasedBeforeScheduledEmailTest < Test::Unit::TestCase
  def setup
    @pre_time       = Time.local(2006, 1, 1, 12, 0, 0)
    @release_time   = Time.local(2006, 2, 1, 0, 0, 0)
    @mid_time       = Time.local(2006, 2, 1, 12, 0, 0)
    @schedule_time  = Time.local(2006, 2, 2, 0, 0, 0)
    @post_time      = Time.local(2006, 2, 2, 12, 0, 0)

    @email = parties(:bob).account.emails.build(:current_user => parties(:bob))
    @sender = Sender.new(:party => parties(:bob), :name => parties(:bob).name.to_forward_s, 
        :address => parties(:bob).main_email.address)
    @email.update_attributes(:scheduled_at => @schedule_time, :sender => @sender, 
        :body => "body text", :subject => "subject",
        :tos => parties(:mary).main_email.address)
    #@email = Email.create!(:subject => 'test', :body => 'body text', :sender => Party.find(:first))
    #@email.update_attribute(:scheduled_at, @schedule_time)

    @email.release!(@release_time)
  end

  def test_status_is_ready_after_release_and_schedule_time
    assert_equal :ready, @email.status
  end
end

class ReleasedScheduledAndScheduledBeforeReleasedEmailTest < Test::Unit::TestCase
  def setup
    @pre_time       = Time.local(2006, 1, 1, 12, 0, 0)
    @schedule_time  = Time.local(2006, 2, 1, 0, 0, 0)
    @mid_time       = Time.local(2006, 2, 1, 12, 0, 0)
    @release_time   = Time.local(2006, 2, 2, 0, 0, 0)
    @post_time      = Time.local(2006, 2, 2, 12, 0, 0)

    @email = parties(:bob).account.emails.build(:current_user => parties(:bob))
    @sender = Sender.new(:party => parties(:bob), :name => parties(:bob).name.to_forward_s, 
        :address => parties(:bob).main_email.address)
    @email.update_attributes(:scheduled_at => @now, :sender => @sender, 
        :body => "body text", :subject => "subject",
        :tos => parties(:mary).main_email.address)
    #@email = Email.create!(:subject => 'test', :body => 'body text', :sender => Party.find(:first))
    #@email.update_attribute(:scheduled_at, @now)

    @email.release!(@release_time)
  end

  def test_status_is_ready_after_release_and_schedule_time
    assert_equal :ready, @email.status
  end
end

class EmailReplyingTest < Test::Unit::TestCase
  def setup
    @sender = parties(:bob)
    @receiver = parties(:mary)

    @email = parties(:bob).account.emails.build(:current_user => parties(:bob))
    @sender = Sender.new(:party => parties(:bob), :name => parties(:bob).name.to_forward_s, 
        :address => parties(:bob).main_email.address)
    @email.update_attributes(:sent_at => 2.hours.ago, :received_at => 1.hour.ago, :sender => @sender, 
        :body => "original body\nline2", :subject => "original subject",
        :tos => parties(:mary).main_email.address)
    #@email = Email.create!(:subject => 'original subject', :body => "original body\nline2", :sender => @sender, :sent_at => 2.hours.ago, :received_at => 1.hour.ago)
    #@email.to.create!(:party => @receiver)

    @email.reload
    @reply = @email.reply(@receiver)
  end

  def test_has_one_recipient
    assert_equal 1, @email.tos.size
  end

  def test_reply_to_original_sender
    assert_equal @sender.name.to_s, @reply.tos.first.party.name.to_s
  end

  def test_sender_is_original_recipient
    assert_equal @receiver.name.to_s, @reply.sender.party.name.to_s
  end

  def test_reply_is_valid
    assert @reply.valid?
  end

  def test_recipient_count_after_save_is_one
    @reply.save!
    assert_equal 1, @reply.tos.size
  end

  def test_reply_body_mentions_original_sender
    assert_match /#{Regexp.escape(@sender.name.to_s)} said/i, @reply.body
  end

  def test_reply_body_mentions_original_sent_date_time
    assert_match /on #{Regexp.escape(@email.received_at.strftime('%Y-%m-%d %H:%M'))}/i, @reply.body
  end

  def test_reply_body_line_2
    assert_match /^>\sline2/, @reply.body
  end
end

class ReplyToAllWhereOnePartyIsAddressedThroughMultipleEmailAddressesTest < Test::Unit::TestCase
  def setup
    @bob = parties(:bob)
    @mary = parties(:mary)
    @mary.email_addresses.create!(:address => "mary@xlsuite.com")

    @email = @bob.account.emails.build(:current_user => parties(:bob))
    @sender = Sender.new(:party => @bob, 
        :name => @bob.name.to_forward_s, 
        :address => @bob.main_email.email_address, :account => @email.account)
    @email.attributes = {:subject => 'original subject', :body => 'original body', :sender => @sender, 
        :sent_at => Time.local(2006, 8, 30, 11, 30, 0), :received_at => Time.local(2006, 8, 30, 11, 30, 0),
        :tos => @mary.email_addresses.map(&:address).join(", ")}
    @email.save!

    @email.reload
    @reply = @email.reply_to_all(@mary)
    @reply.save!
    @reply.reload
  end

  def test_no_recipient_has_errors
    assert_equal "", (@reply.tos + @reply.ccs).map(&:errors).flatten.map(&:full_messages).to_s
  end

  def test_mary_is_the_new_sender
    assert_not_nil @reply.sender
    assert_equal @mary, @reply.sender.party
  end

  def test_bob_is_the_new_to
    assert_equal [@bob].map(&:name).map(&:to_s), @reply.tos.map(&:party).map(&:name).map(&:to_s)
  end

  def test_replies_to_all_email_addresses
    expected, actual = Hash.new, Hash.new
    # {"mary@xlsuite" => @mary, "mary@teksol" => @mary}
    (@mary.email_addresses - [@mary.main_email]).each do |route|
      expected[route.address] = @mary.name.to_s
    end

    @reply.ccs.each do |recipient|
      actual[recipient.address] = recipient.party.name.to_s
    end

    assert_equal expected, actual
  end
end

class SameEmailAddressInRecipientsUniquedTest < Test::Unit::TestCase
  def setup
    @bob = parties(:bob)
    @mary = parties(:mary)
    @john = parties(:john)
    @peter = parties(:peter)

    @email = @bob.account.emails.build(:current_user => parties(:bob))
    @sender = Sender.new(:party => @bob, 
        :name => @bob.name.to_forward_s, 
        :address => @bob.main_email.email_address, :account => @email.account)
    @email.attributes = {:subject => 'original subject', :body => 'original body', :sender => @sender, 
        :sent_at => Time.local(2006, 8, 30, 11, 30, 0), :received_at => Time.local(2006, 8, 30, 11, 30, 0),
        :tos => [@mary.main_email.email_address, @mary.main_email.email_address].join(", ")}
    @email.save!

    @email.reload
  end

  def test_mary_not_there_twice
    assert_equal [@mary].map(&:name).sort.map(&:to_s),
        @email.tos.map(&:party).map(&:name).sort.map(&:to_s)
  end
end

class ReplyToAllWhereTheCcIsReplyingTest < Test::Unit::TestCase
  def setup
    @bob = parties(:bob)
    @mary = parties(:mary)
    @john = parties(:john)
    @peter = parties(:peter)

    @email = @bob.account.emails.build(:current_user => parties(:bob))
    @sender = Sender.new(:party => @bob, 
        :name => @bob.name.to_forward_s, 
        :address => @bob.main_email.email_address, :account => @email.account)
    @email.attributes = {:subject => 'original subject', :body => 'original body', :sender => @sender, 
        :sent_at => Time.local(2006, 8, 30, 11, 30, 0), :received_at => Time.local(2006, 8, 30, 11, 30, 0),
        :tos => [@mary.main_email.email_address, @peter.main_email.email_address].join(", "),
        :ccs => @john.main_email.email_address}
    @email.save!

    @email.reload
    @reply = @email.reply_to_all(@john)
    @reply.save!
    @reply.reload
  end

  def test_no_recipient_has_errors
    assert_equal "", (@reply.tos + @reply.ccs).map(&:errors).flatten.map(&:full_messages).to_s
  end

  def test_john_is_the_new_sender
    assert_not_nil @reply.sender
    assert_equal @john, @reply.sender.party
  end

  def test_bob_is_the_new_to
    assert_equal [@bob].map(&:name).map(&:to_s), @reply.tos.map(&:party).map(&:name).map(&:to_s)
  end

  def test_mary_and_peter_are_ccd
    assert_equal [@mary, @peter].map(&:name).map(&:to_s).sort,
        @reply.ccs.map(&:party).map(&:name).map(&:to_s).sort
  end

  def test_has_three_recipients
    assert_equal 3, @reply.tos.size + @reply.ccs.size + @reply.bccs.size,
        "Found: #{(@reply.tos + @reply.ccs + @reply.bccs).flatten.map(&:party).map(&:name).map(&:to_s).inspect}"
  end
end

class ReplyToAllWithManyTosTest < Test::Unit::TestCase
  def setup
    @bob = parties(:bob)
    @mary = parties(:mary)
    @john = parties(:john)
    @peter = parties(:peter)

    @email = @bob.account.emails.build(:current_user => parties(:bob))
    @sender = Sender.new(:party => @bob, 
        :name => @bob.name.to_forward_s, 
        :address => @bob.main_email.email_address, :account => @email.account)
    @email.attributes = {:subject => 'original subject', :body => 'original body', :sender => @sender, 
        :sent_at => Time.local(2006, 8, 30, 11, 30, 0), :received_at => Time.local(2006, 8, 30, 11, 30, 0),
        :tos => [@mary.main_email.email_address, @peter.main_email.email_address].join(", "),
        :ccs => @john.main_email.email_address}
    @email.save!

    @email.reload
    @reply = @email.reply_to_all(@mary)
    @reply.save!
    @reply.reload
  end

  def test_no_recipient_has_errors
    assert_equal "", (@reply.tos + @reply.ccs).map(&:errors).flatten.map(&:full_messages).to_s
  end

  def test_mary_is_the_new_sender
    assert_not_nil @reply.sender
    assert_equal @mary, @reply.sender.party
  end

  def test_bob_is_the_new_to
    assert_equal [@bob].map(&:name).map(&:to_s), @reply.tos.map(&:party).map(&:name).map(&:to_s)
  end

  def test_john_and_peter_are_ccd
    assert_equal [@john, @peter].map(&:name).map(&:to_s).sort,
        @reply.ccs.map(&:party).map(&:name).map(&:to_s).sort
  end

  def test_has_three_recipients
    assert_equal 3, @reply.tos.size + @reply.ccs.size + @reply.bccs.size,
        "Found: #{(@reply.tos + @reply.ccs + @reply.bccs).flatten.map(&:party).map(&:name).map(&:to_s).inspect}"
  end
end

class ReplyToAllTest < Test::Unit::TestCase
  def setup
    @bob = parties(:bob)
    @mary = parties(:mary)
    @john = parties(:john)
    @peter = parties(:peter)

    @email = @bob.account.emails.build(:current_user => parties(:bob))
    @sender = Sender.new(:party => @bob, 
        :name => @bob.name.to_forward_s, 
        :address => @bob.main_email.email_address, :account => @email.account)
    @email.attributes = {:subject => 'original subject', :body => 'original body', :sender => @sender, 
        :sent_at => Time.local(2006, 8, 30, 11, 30, 0), :received_at => Time.local(2006, 8, 30, 11, 30, 0),
        :tos => @mary.main_email.email_address,
        :ccs => [@john.main_email.email_address, @peter.main_email.email_address].join(",")}
    @email.save!

    @email.reload
    @reply = @email.reply_to_all(@mary)
    @reply.save!
    @reply.reload
  end

  def test_no_recipient_has_errors
    assert_equal "", (@reply.tos + @reply.ccs).map(&:errors).flatten.map(&:full_messages).to_s
  end

  def test_mary_is_the_new_sender
    assert_not_nil @reply.sender
    assert_equal @mary, @reply.sender.party
  end

  def test_bob_is_the_new_to
    assert_equal [@bob].map(&:name).map(&:to_s), @reply.tos.map(&:party).map(&:name).map(&:to_s)
  end

  def test_john_and_peter_are_kept_as_ccs
    assert_equal [@john, @peter].map(&:name).map(&:to_s).sort,
        @reply.ccs.map(&:party).map(&:name).map(&:to_s).sort
  end

  def test_has_three_recipients
    assert_equal 3, @reply.tos.size + @reply.ccs.size + @reply.bccs.size,
        "Found: #{(@reply.tos + @reply.ccs + @reply.bccs).flatten.map(&:party).map(&:name).map(&:to_s).inspect}"
  end
end

class ForwardEmailTest < Test::Unit::TestCase
  def setup
    @sender = parties(:bob)
    @receiver = parties(:mary)

    @email = @sender.account.emails.build(:current_user => @sender)
    @sender_object = Sender.new(:party => @sender, 
        :name => @sender.name.to_forward_s, 
        :address => @sender.main_email.email_address, :account => @email.account)
    @email.attributes = {:subject => 'original subject', :body => 'original body', :sender => @sender_object, 
        :sent_at => Time.local(2006, 8, 30, 11, 30, 0), :received_at => Time.local(2006, 8, 30, 11, 30, 0),
        :tos => @receiver.main_email.email_address}
    @email.save!

    #@email = Email.create!(:subject => 'original subject', :body => 'original body',
    #  :sender => @sender, :sent_at => Time.local(2006, 8, 30, 11, 30, 0),
    #         :received_at => Time.local(2006, 8, 30, 11, 30, 0))
    #@email.to.create!(:party => @receiver)

    @email.reload
    @forward = @email.forward(@receiver)
  end

  def test_receiver_is_sender
    assert_equal @forward.sender.party.name.to_s, @receiver.name.to_s
  end

  def test_subject_says_forward_from
    assert_match /^fwd:\s#{@email.subject}/i, @forward.subject
  end

  def test_body_contains_forwarded_information
    assert_match /^Begin Forwarded Message:/i, @forward.body
    assert_match /^>\s+from:\s+#{Regexp.escape(@sender_object.to_formatted_s)}/i, @forward.body
    assert_match /^>\s+to:\s+#{Regexp.escape(@email.tos.first.to_formatted_s)}/i, @forward.body
    assert_match /^>\s+subject:\s+#{Regexp.escape(@email.subject)}/i, @forward.body
    assert_match /^>\s+date:\s+#{Regexp.escape(@email.received_at.strftime('%Y-%m-%d %H:%M'))}/i, @forward.body
  end

  def test_body_contains_previous_body_indented
    assert_match /^>\soriginal body/, @forward.body
  end
end

class EmailWithOneRecipientInEachCategoryTest < Test::Unit::TestCase
  def setup
    @bob = parties(:bob)
    @mary = parties(:mary)
    @john = parties(:john)
    @peter = parties(:peter)

    @email = @bob.account.emails.build(:current_user => @bob)
    @sender = Sender.new(:party => @bob, 
        :name => @bob.name.to_forward_s, 
        :address => @bob.main_email.email_address, :account => @email.account)
    @email.attributes = {:subject => 'a', :body => 'b', :sender => @sender, 
        :sent_at => 5.minutes.ago, :received_at => 2.minutes.ago,
        :tos => @mary.main_email.email_address,
        :ccs => @john.main_email.email_address, 
        :bccs => @peter.main_email.email_address}
    @email.save!

    #@email = Email.create!(:subject => 'a', :body => 'b', :sent_at => 5.minutes.ago, :received_at => 2.minutes.ago, :sender => parties(:bob))
    #@email.to.create!(:party => parties(:mary))
    #@email.cc.create!(:party => parties(:john))
    #@email.bcc.create!(:party => parties(:peter))
    #@email.save!
    @email.reload
  end

  def test_there_are_three_recipients
    assert_equal 3, @email.tos.size + @email.ccs.size + @email.bccs.size
  end

  def test_mary_is_in_the_to_field
    assert @email.tos.find(:first, :conditions => ['party_id = ?', parties(:mary).id])
  end

  def test_john_is_in_the_cc_field
    assert @email.ccs.find(:first, :conditions => ['party_id = ?', parties(:john).id])
  end

  def test_peter_is_in_the_bcc_field
    assert @email.bccs.find(:first, :conditions => ['party_id = ?', parties(:peter).id])
  end
end

=begin
TODO can't reproduce this test anymore because the email object has a recipients_cant_be_blank validation
class MarkingARecipientAsBadUnreleasesTheEmailTest < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
    
    party = @account.parties.create!
    EmailContactRoute.create!(:name => "Main", :address => "jim@teksol.info", :routable => party, :account => party.account)    
    @sender = Sender.new(:account => @account, :party => party,
        :address => party.main_email.address, :name => party.name.to_s)

    @email = @account.emails.build(:subject => 'test', :body => 'test', :current_user => party)
    @email.update_attributes(:sender => @sender, :tos => "")    
    
    # TODO
    # are these following lines of code replaced by the previous block? i don't think so
    # @email = @account.emails.create!(:subject => 'test', :body => 'test', :sender => @account.parties.create!)
    # EmailContactRoute.create!(:name => "Main", :address => "jim@teksol.info", :routable => party)
    # @recipient = @email.tos.create!(:source => 'to', :party => @account.parties.create!, :extras => {})
    
    @email.release!

    @original_count = Email.count

    @email.send!

    @email.reload
    @recipient.reload

    @new_mail = Email.find(:first, :order => 'id DESC')
  end

  def test_x_email_unreleased
    assert !@email.ready?
  end

  def test_x_recipient_not_sent
    assert !@recipient.sent?
  end

  def test_x_returned_mail_to_sender
    assert_equal @original_count + 1, Email.count
  end

  def test_x_new_mail_about_the_one_in_error
    assert_equal @email, @new_mail.about
  end

  def test_x_new_mail_mentions_missing_email_address
    assert_match /No E-Mail address defined in Party/i, @new_mail.body
  end
end
=end

class EmailSenderAssignmentTest < Test::Unit::TestCase
  def setup
    @bob = parties(:bob)
    @email = Account.find(:first).emails.build(:current_user => @bob)
  end

  def test_with_sender_object
    @email.sender = Sender.new(:address => @bob.main_email.address, :name => @bob.name.to_s)
    @email.save_without_validation
    assert_kind_of Sender, @email.reload.sender
  end

  def test_with_hash_of_params
    @email.sender = {:address => @bob.main_email.address, :name => @bob.name.to_s}
    @email.save_without_validation
    assert_kind_of Sender, @email.reload.sender
  end
end
