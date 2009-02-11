require File.dirname(__FILE__) + '/../test_helper'

module RecipientTest
  class GeneralRecipientTest < Test::Unit::TestCase
    def setup
      @account = Account.find(:first)

      @party = @account.parties.create!
      EmailContactRoute.create!(:address => "bingo@nowhere.com", :routable => @party, :name => "main")
      @party.reload

      @email = @account.emails.build(
          :subject => 'something to talk about',
          :body => 'I really want to talk about you',
          :sender => parties(:bob), :account => @account)
    
      @recipient = @email.tos.build(:account => @account, :party => @party, 
          :name => @party.name.to_s, :address => @party.main_email.address, :email => @email)
      @email.save!
      
      ActionMailer::Base.deliveries = []
    end
    
    def test_account_association
      assert_equal @account, @recipient.account
    end
  
    def test_unread_reported_as_nil_read_time
      assert_nil @recipient.read_at
    end
  
    def test_read_stores_current_time
      @recipient.read!(Time.utc(2006, 2, 14, 23, 4, 0))
      assert_equal Time.utc(2006, 2, 14, 23, 4, 0), @recipient.reload.read_at
    end
  
    def test_unsent_reported_as_nil_sent_time
      assert_nil @recipient.sent_at
    end
  
    def test_send_sets_sent_time
      @recipient.send!(Time.utc(2006, 2, 14, 23, 6, 0))
      assert_equal Time.utc(2006, 2, 14, 23, 6, 0), @recipient.reload.sent_at
    end
  
    # TODO there should be no message_id generated, recipients table does not have message_id column anymore
    #def test_send_generates_a_message_id
    #  @recipient.send!
    #  assert !@recipient.message_id.blank?
    #end
  
    def test_send_copies_party_principal_email_to_recipient
      EmailContactRoute.create!(:address => "sam@singapour.net", :routable => @party, :name => "alt")
      @party.reload
      @recipient.send!
      assert_equal @party.main_email.address, @recipient.address
    end
  end

  class EmailAddressesBuilderRecipientTest < Test::Unit::TestCase    
    def test_return_email_addresses_of_parties_inside_a_group
      recipient = recipients(:group_recipients)
      assert_equal 2, recipient.email_addresses.size, recipient.email_addresses.to_sentence
      assert_include parties(:bob).main_email.address, recipient.email_addresses.to_sentence
      assert_include parties(:mary).main_email.address, recipient.email_addresses.to_sentence
      assert_not_include parties(:peter).main_email.address, recipient.email_addresses.to_sentence
    end

    def test_nil_builder_type_and_id
      recipient = recipients(:nil_builder_type_and_id)
      assert_include "test@test.com", recipient.email_addresses.to_s
    end
  end
end
