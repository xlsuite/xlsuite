require File.dirname(__FILE__) + '/../test_helper'

module ContactRequestTest
  class AbilityToFindTest < Test::Unit::TestCase
    def setup
      ContactRequest.delete_all
      @account = Account.find(:first)
      @completed = @account.contact_requests.create!(:name => "Johnny", :subject => "Problem", :completed_at => 5.minutes.ago)
      @incomplete = @account.contact_requests.create!(:name => "John", :subject => "Help")
    end

    def test_incomplete_only
      assert_equal [@incomplete], @account.contact_requests.incomplete.find(:all)
    end

    def test_completed_only
      assert_equal [@completed], @account.contact_requests.completed.find(:all)
    end

    def test_scoped_first_completed
      assert_equal @completed, @account.contact_requests.completed.find(:first)
    end

    def test_scoped_first_incomplete
      assert_equal @incomplete, @account.contact_requests.incomplete.find(:first)
    end

    def test_by_qualified_id
      assert_raises(ActiveRecord::RecordNotFound) { @account.contact_requests.completed.find(@incomplete.id) }
      assert_equal @completed, @account.contact_requests.completed.find(@completed.id)
    end

    def test_as_implemented_by_active_record_unchanged
      assert_equal @incomplete, @account.contact_requests.find(@incomplete.id)
      assert_equal @completed, @account.contact_requests.find(@completed.id)
      assert_equal @incomplete, @account.contact_requests.find(:first, :conditions => ["subject LIKE ?", "Help"])
      assert_equal [@completed], @account.contact_requests.find(:all, :conditions => ["completed_at IS NOT NULL"])
      assert_equal 2, @account.contact_requests.find(:all).size
    end
  end

  class AbilityToCountTest < Test::Unit::TestCase
    def setup
      ContactRequest.delete_all
      @account = Account.find(:first)
      @completed = @account.contact_requests.create!(:name => "Johnny", :subject => "Problem", :completed_at => 5.minutes.ago)
      @incomplete = @account.contact_requests.create!(:name => "John", :subject => "Help")
    end

    def test_completed_only
      assert_equal 1, @account.contact_requests.completed.count
      assert_equal 0, @account.contact_requests.completed.count(:conditions => ["subject LIKE ?", "Help"])
    end

    def test_incomplete_only
      assert_equal 1, @account.contact_requests.incomplete.count
      assert_equal 0, @account.contact_requests.incomplete.count(:conditions => ["subject LIKE ?", "Problem"])
    end

    def test_as_implemented_by_active_record_unchanged1
      assert_equal 2, @account.contact_requests.count
      # the following assert will return one because one of the contact requests completed_at is null
      assert_equal 1, @account.contact_requests.count(:all, :conditions => ["completed_at <= ?", 10.minutes.ago])
    end
  end

  class AssociationWithAnExistingPartyTest < Test::Unit::TestCase
    def setup
      @account = Account.find(:first)
      @party = @account.parties.create!
      @email = @party.main_email
      @email.update_attributes!(:address => "bill@xlsuite.org")
      @phone = @party.main_phone
      @phone.update_attributes!(:number => "604 111 2224")
    end

    def test_associate_to_existing_party_through_email_address
      request = @account.contact_requests.build(:email => "bill@xlsuite.org",
          :name => "Bill", :subject => "Need help with your site")
      # need to do this operation after the defensio is implemented
      request.params[:email_address] = { "Main" => {:email_address => "bill@xlsuite.org" }}
      # need to pass in phone as parameters as well so that ContactRequest#save_contact_routes_to_party(party, params) doesnt return errors
      request.params["phone"] = {"Main" => {:number => "1112223333"}}
      assert_nothing_raised { request.save! }
      assert_equal true, request.create_party
      assert_equal @party, request.reload.party
    end

    def test_not_associate_to_existing_party_through_phone
      party_count = Party.count
      request = @account.contact_requests.build(:name => "Bill", :subject => "Need help with your site")
      # need to do this operation after the defensio is implemented
      request.params[:phone] = { "Main" => {:number => "604 111 2224" }}
      request.params[:party] = {:first_name => "Bill"}
      assert_nothing_raised { request.save! }
      request.create_party
      assert_equal party_count+1, Party.count 
      assert_equal "Bill", request.party.first_name
    end

    def test_not_associate_to_existing_party_through_similar_phone
      assert_difference Party, :count, 1 do
        request = @account.contact_requests.build(:name => "Bill", :subject => "Need help with your site")
        # need to do this operation after the defensio is implemented
        request.params[:phone] = { "Main" => {:number => "(604) 111-2224" }}
        request.params[:party] = {:first_name => "Bill"}
        assert_nothing_raised { request.save! }
        request.create_party
        assert_equal "Bill", request.party.first_name
      end
    end
  end

  class AssociationWhenNoExistingPartyTest < Test::Unit::TestCase
    def setup
      @account = Account.find(:first)
    end

    def test_will_create_new_party_with_provided_phone
      request = @account.contact_requests.build(:name => "Bill", :subject => "Need help with your site")
      # need to do this operation after the defensio is implemented
      request.params[:phone] = { "Main" => {:number => "604 111 2224" }}
      assert_equal true, request.save
      assert_difference Party, :count, 1 do
        request.create_party
      end

      assert_not_nil request.reload.party
      assert_equal "604 111 2224", request.party.main_phone.number
    end

    def test_will_create_new_party_with_provided_email
      request = @account.contact_requests.build(:email => "bill@xlsuite.org",
          :name => "Bill", :subject => "Need help with your site")
      # need to do this operation after the defensio is implemented
      request.params[:email_address] = { "Main" => {:email_address => "bill@xlsuite.org" }}
      request.params[:party] = {:first_name =>"Bill"}
      assert_equal true, request.save
      assert_difference Party, :count, 1 do
        request.create_party
      end

      assert_not_nil request.reload.party
      assert_equal "bill@xlsuite.org", request.party.main_email.address
    end
  end

  class ContactRequestTest < Test::Unit::TestCase
    def setup
      @account = Account.find(:first)
      @request = @account.contact_requests.create!(:name => "John", :subject => "Help")
    end

    def test_can_be_completed
      @request.complete!
      assert @request.reload.completed?
      assert_not_nil @request.completed_at
    end
  end
end
