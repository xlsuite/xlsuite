require File.dirname(__FILE__) + '/../test_helper'

class AccountTest < Test::Unit::TestCase
  def setup
    @party = Party.create!(:account => Account.find(:first))
  end
    
  context "Each party" do
    should "owns at most one account" do
      @account = Account.new(:owner => @party);
      @account.expires_at = 1.hour.from_now
      @account.save!
  
      @future_account = Account.new(:owner => @party)
      @future_account.expires_at = 1.hour.from_now
      assert !@future_account.valid?
    end
  end
  
  context "Activating an account" do
    setup do
      @account = Account.new(:owner => @party)
      @account.expires_at = 1.hour.from_now
      @account.confirmation_token = UUID.random_create.to_s
      @account.confirmation_token_expires_at = 30.minutes.from_now
      @account.save!
      assert_not_nil @account.confirmation_token
      assert_not_nil @account.confirmation_token_expires_at
    end
    
    context "that has state and country" do
      setup do
        address = @party.main_address
        address.update_attributes!(:country => "CA", :state => "BC")
        @account.reload
      end
      
      should "activate successfully" do
        assert @account.activate!
      end
    end
    
    context "with no state nor country" do
      setup do
        @account.reload
      end
      
      should "return cannot activate exception" do
        assert_raise ActiveRecord::RecordInvalid do
          @account.activate!
        end
      end
    end
  end
  
  context "An account option" do
    setup do
      @account = accounts(:wpul)
    end

    should "defaulted to false" do
      deny @account.options.rets?
    end
  end
  
  context "Setting an account option" do
    setup do 
      @account = accounts(:wpul)
      @account.options.rets = true
    end
    
    should "set the option correctly" do
      assert @account.options.rets?
    end
    
    context "and saving it" do
      setup do
        @account.save!
      end

      should "return the correct value after a reload" do
        @account.reload
        assert @account.options.rets?, "RETS option wasn't saved or restored"
      end
    end
  end
  
  context "A newly saved account" do
    setup do
      @account = Account.new
      @account.expires_at = 1.hour.from_now
      @account.save!
  
      @party = Party.create!(:account => @account)
      @account.owner = @party
      @account.save!
    end
    
    %w( configurations payments contact_requests
        emails estimates feeds forums forum_topics forum_posts
        invoices links link_categories product_categories
        groups forum_categories listings
        products mass_recipients tags testimonials pages layouts).each do |table|
      should("have a has_many #{table} relation") do
        assert_equal [], @account.send(table, true)
      end
    end

    should "have created a CopyAccountConfigurationsFuture for itself" do
      assert_kind_of CopyAccountConfigurationsFuture, @account.futures.find(:all).first
    end
    
    should "has the has_many parties relation" do
      assert_equal [@party], @account.parties(true)
    end
  end
  
  context "Assigning an account owner" do
    setup do 
      @account = Account.new
      @account.expires_at = 1.hour.from_now
      @account.save!
  
      @party = Party.create!(:account => @account, :first_name => "account", :last_name => "owner")
      @party.email_addresses.create!(:email_address => "aloha@test.com", :account => @account)
      @party.links.create!(:url => "xlsuite.com", :account => @account)
      @party.addresses.create!(:line1 => "This Is Line 1", :account => @account)
      @party.phones.create!(:number => "6667778888", :account => @account)
      @party.reload

      @account.owner = @party
      @account.save!
    end
    
    should "had the account owner info saved into all master accounts" do
      master_accounts = Account.find_all_by_master(true)
      master_accounts.each do |master_account|
        assert_not_nil party=master_account.parties.find_by_first_name("account")
        assert_equal @party.main_email.email_address, party.main_email.email_address
        assert_equal @party.main_address.line1, party.main_address.line1
        assert_equal @party.main_phone.number, party.main_phone.number
        assert_equal @party.main_link.url, party.main_link.url
      end
    end
  end
  
  context "A new account object" do
    setup do
      @account = Account.new
    end
    
    should "not be expired when expiring in the far future" do
      @account.expires_at = 10.years.from_now; @account.save!
      assert !@account.expired?
      assert !@account.nearly_expired?
    end
    
    should "be nearly expired when expiring in less than seven days" do
      @account.expires_at = 7.days.from_now; @account.save!
      assert !@account.expired?
      assert @account.nearly_expired?
    end
    
    should "be expired but not nearly expired when the account is already expired" do
      @account.expires_at = 1.hour.ago; @account.save!
      assert @account.expired?
      assert !@account.nearly_expired?
    end
  end
  
  context "Signing up for a child account" do
    setup do
      @master_account = Account.find_by_master(true)
      @master_address = @master_account.owner.main_address
      @account = create_account(:expires_at => 10.hours.from_now)
      @account.domains.create!(:name => "mydomain.com")
      @owner = @account.parties.create!(:first_name => "Jon")
      @account.owner = @owner; @account.save!
      @address = @owner.main_address
      @address.update_attributes!(:name => "Office", :country => "CAN", :state => "QC")
      @account.owner.reload
      @account.stubs(:cost).returns("10.00".to_money)
    end
    
    context "calling Account#generate_order_on!" do
      setup do
        @order_count = Order.count
        @order = @account.generate_order_on!(@master_account)
      end
      
      should "create an order in the master account" do
        assert_equal @order_count + 1, Order.count
        deny @order.new_record?
        assert_equal @master_account.id, @order.account_id
      end
      
      should "relate the created order object to the child account" do
        assert_equal @account.id, @order.referencable.id 
      end
      
      should "set the child account's order to the new order" do
        assert_equal @order.id, @account.order_id
      end
    end
    
    should "set no taxes if child account is in a different country and state from the master account" do
      @master_address.update_attributes!(:state => "VA", :country => "USA")
  
      @master_address.reload
      assert_equal "USA".downcase, @master_address.country.downcase
      assert_equal "VA".downcase, @master_address.state.downcase
      assert_not_equal @master_address.country, @address.country
      assert_not_equal @master_address.state, @address.state
  
      @order = @account.generate_order_on!(@master_account)
      assert !@order.fst_active? && !@order.pst_active?,
          "fst_active? #{@order.fst_active}, pst_active? #{@order.pst_active}"
    end
    
    should "set no taxes if child account is in a different country but the same state" do
      @master_address.update_attributes!(:state => "QC", :country => "USA")
      @address.update_attributes!(:state => @master_address.state)
  
      @master_address.reload
      assert_equal "USA".downcase, @master_address.country.downcase
      assert_equal "QC".downcase, @master_address.state.downcase
      assert_not_equal @master_address.country, @address.country
      assert_equal @master_address.state, @address.state
  
      @order = @account.generate_order_on!(@master_account)
      assert !@order.fst_active? && !@order.pst_active?,
          "fst_active? #{@order.fst_active}, pst_active? #{@order.pst_active}"
    end
    
    should "set fst only when the child account is in a different state but the same country" do
      @master_address.update_attributes!(:state => "BC", :country => "CAN")
      @address.update_attributes!(:country => @master_address.country)
  
      @master_address.reload
      assert_equal "CAN".downcase, @master_address.country.downcase
      assert_equal "BC".downcase, @master_address.state.downcase
      assert_equal @master_address.country, @address.country
      assert_not_equal @master_address.state, @address.state
  
      @order = @account.generate_order_on!(@master_account)
      assert @order.fst_active? && !@order.pst_active?,
          "fst_active? #{@order.fst_active}, pst_active? #{@order.pst_active}"
    end
    
    should "set fst and gst when the child account is on the same state and country" do
      @master_address.update_attributes!(:state => "QC", :country => "CAN")
      @address.update_attributes!(:country => @master_address.country, :state => @master_address.state)
  
      @master_address.reload
      assert_equal "CAN".downcase, @master_address.country.downcase
      assert_equal "QC".downcase, @master_address.state.downcase
      assert_equal @master_address.country, @address.country
      assert_equal @master_address.state, @address.state
  
      logger.debug {"
  @owner:           #{@owner.id}, #{@owner.display_name}
  @master_address:  #{@master_address.id}, #{@master_address.country}, #{@master_address.state}, #{@master_address.new_record?}
  @address:         #{@address.id}, #{@address.country}, #{@address.state}, #{@address.new_record?}
  "}
  
      @order = @account.generate_order_on!(@master_account)
      assert @order.fst_active? && @order.pst_active?,
          "fst_active? #{@order.fst_active}, pst_active? #{@order.pst_active}"
    end
  end
end
