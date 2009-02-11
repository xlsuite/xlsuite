require File.dirname(__FILE__) + '/../test_helper'
require 'accounts_controller'

# Re-raise errors caught by the controller.
class AccountsController; def rescue_action(e) raise e end; end

class AccountsControllerTest < Test::Unit::TestCase
  setup do
      @controller = AccountsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
  
      @account = Account.find(:first)
  end

  context "A non superuser" do
    setup do
      @admin = login!(:bob)
      @admin.superuser = false
      @admin.save!
    end

    should "not be able to view the accounts list" do
      get :index
      assert_response :missing
      assert_template "shared/missing"
    end

    should "not be able to get account details" do
      get :edit, :id => @account.id
      assert_response :missing
      assert_template "shared/missing"
    end

    should "not be able to change account details" do
      put :update, :id => @account.id, :account => {}
      assert_response :missing
      assert_template "shared/missing"
    end

    should "not be able to delete an account" do
      post :destroy, :id => @account.id
      assert_response :missing
      assert_template "shared/missing"
    end

    should "not be able to create an account" do
      post :create, :account => {}
      assert_response :success
      assert_template "new"
    end
  
    should "not be able to attempt to create an account" do
      get :new
      assert_response :success
      assert_template "new"
    end
  end

  context "A superuser" do
    setup do
      @admin = login!(:bob)
      @admin.superuser = true
      @admin.save!
    end

    should "PUT #update and change account options" do
      put :update, :id => @account, :account => {:rets_option => "1"}
      assert @account.reload.options.rets?, "RETS option wasn't saved or serialized"
      assert @account.rets_option, "Option not saved correctly"
    end  
  
    should "GET #index" do
      get :index
      assert_template "index"
      assert_kind_of Array, assigns(:accounts)
    end
  
    should "GET #edit" do
      get :edit, :id => @account.id
      assert_template "edit"
      assert_not_nil assigns(:acct)
    end
  
    should "GET #new" do
      get :new
      assert_template "new"
      assert_not_nil assigns(:acct)
    end
  
    should "PUT #update and change account details" do
      put :update, :id => @account.id, :commit => "Close",
          :account => {:expires_at => "next month"}
      assert_response :success
      assert_not_nil assigns(:acct)
      assert_equal Chronic.parse("next month").to_s(:iso),
          assigns(:acct).reload.expires_at.to_s(:iso)
    end
  
    should "DELETE #destroy and destroy an account" do
      assert_difference Account, :count, -1 do
        post :destroy, :commit => "Destroy", :id => @account.id
      end
  
      assert_redirected_to :action => :index
      assert_raises(ActiveRecord::RecordNotFound) { Account.find(@account.id) }
    end
  end

  context "An anonymous user" do
    setup do
      @request.host = "unknown.xlsuite.com"
      @params = {:account => {}, :commit => "paypal", :domain => {:name => @request.host},
        :email => {:email_address => "jon.singer@want.com"}}
    end

    should "replace the expiration date with the hard-coded one" do
      Configuration.set_default(:account_expiration_duration_in_seconds, 15.minutes)
      Configuration.set_default(:account_base_cost, 15.00)
  
      @params[:account][:expires_at] = "next week"
      post :create, @params
      assert_not_nil assigns(:acct)
  
      now = 15.minutes.from_now
      interval = (now - 5.seconds .. now + 5.seconds)
      assert interval.include?(assigns(:acct).expires_at),
          "Account expiration not set to 15 minutes: #{assigns(:acct).expires_at.inspect}, range is: #{interval.inspect}"
    end

    should "create the account and domain" do
      post :create, @params.merge(:commit => "Pay with Credit Card")
      assert_not_nil domain = Domain.find_by_name(@request.host), "Domain not created"
      assert_not_nil account = domain.account, "Account not created"
      assert_not_nil owner = account.owner, "Owner could not be found"
    end

    context "activating his account" do
      setup do
        @request.host = "unknown.xlsuite.com"

        assert_difference(Account, :count) do
          post :create, :commit => "Save", 
            :domain => {:name => "unknown.xlsuite.com"},
            :email => {:email_address => "jon.singer@want.com"}
        end

        @domain = Domain.find_by_name("unknown.xlsuite.com")
        @acct = @domain.account
        @owner = @acct.owner
        @master_account = Account.find_by_master(true)

        @params = {:commit => "Confirm", :code => @acct.confirmation_token,
            :owner => {:first_name => "Jon", :last_name => "Singer",
                :password => "patent", :password_confirmation => "patent"},
            :phone => {:name => "work", :number => "123-4567-564"},
            :address => {:name => "office", :line1 => "1234 Jones St",
                :line2 => "", :city => "San Moore", :state => "WA", :zip => "90210", :country => "USA"}}
      end

      should "confirm when using the valid token" do
        get :confirm, :code => @acct.confirmation_token
        assert_template "confirm"
      end

      should "fail when using an invalid token" do
        get :confirm, :code => "abcdef"
        assert_redirected_to "/"
      end

      should "not confirm when the account's token has expired" do
        @acct.confirmation_token_expires_at = 1.year.ago
        @acct.save
        assert_difference(Account, :count, -1) do
          get :confirm, :code => @acct.confirmation_token
        end
      end

      context "giving the correct parameters" do
        setup do
          post :activate, @params
          @owner.reload
          @acct.reload
        end
        
        should "create the owner addresses correctly" do
          assert_equal 1, @owner.addresses.count, "One address created"
          assert_equal "1234 Jones St", @owner.main_address.line1
        end

        should "create the owner phones correctly" do
          assert_equal 1, @owner.phones.count, "One phone created"
          assert_equal "123-4567-564", @owner.main_phone.number
        end
        
        should "set the owner confirmed flag" do
          assert_equal true, @owner.confirmed?
        end
        
        should "set account confirmation_token to nil" do
          assert_nil @acct.confirmation_token
        end
        
        should "set account confirmation_token_expires_at to nil" do
          assert_nil @acct.confirmation_token_expires_at            
        end
        
        should "logged in the owner" do
          assert_equal @owner.id, session[XlSuite::AuthenticatedSystem::CURRENT_USER_ID], "Owner not logged in"
        end
        
        should "set the Domain#activated_at" do
          assert_not_nil @domain.reload.activated_at
        end
        
        should "create the free domain subscription" do
          domain_subscription = @domain.reload.domain_subscription
          assert_not_nil domain_subscription
          assert_equal Money.new(0), domain_subscription.amount
          assert_nil domain_subscription.free_period
          assert_nil domain_subscription.pay_period
        end
      end

      should "not require a payment when the cost is zero" do
        Configuration.set_default(:fst_rate, 0)
        Configuration.set_default(:pst_rate, 0)
        Account.any_instance.stubs(:cost).returns(Money.zero)
        assert_difference Payment, :count, 0 do
          post :activate, @params
        end

        assert_response :redirect
        assert_redirected_to "/admin"
      end

      should "not active when the password confirmation does not match" do
        @params[:owner][:password] = "patent"
        @params[:owner][:password_confirmation] = "animal"
        post :activate, @params
        assert_equal 0, @owner.addresses.count
        assert_equal 0, @owner.phones.count
        assert_not_nil @acct.confirmation_token
        assert_not_nil @acct.confirmation_token_expires_at
        assert_template "confirm"
      end
    end
    
    context "registering for 1234.xlsuite.com" do
      setup do
        @request.host = "1234.xlsuite.com"
        @params = {:account => {}, :commit => "paypal", :domain => {:name => @request.host},
          :email => {:email_address => "jon.singer@want.com"}}
      end
      
      should "create the account and domain" do
        post :create, @params.merge(:commit => "Pay with Credit Card")
        assert_not_nil domain = Domain.find_by_name(@request.host), "Domain not created"
        assert_not_nil account = domain.account, "Account not created"
        assert_not_nil owner = account.owner, "Owner could not be found"
      end
    end
  end

  context "A superuser creating an account" do
    setup do
      @admin = login!(:bob)
      @admin.update_attribute(:superuser, true)

      @params = {:commit => "Save", :account => {:expires_at => "next week"},
            :domain => {:name => "want.com"},
            :owner => {:first_name => "Jon", :last_name => "Singer",
                :password => "patent", :password_confirmation => "patent"},
            :phone => {:name => "work", :number => "123-4567-564"},
            :email => {:email_address => "jon.singer@want.com"},
            :address => {:name => "office", :line1 => "1234 Jones St",
                :line2 => "", :city => "San Moore", :state => "WA", :zip => "90210", :country => "USA"}}
    end

    should "fail when missing the owner's email address" do
      @params[:email][:email_address] = ""
      assert_no_account_created @params
      # Because we are using a transaction around the whole test, we can't
      # test that this specific case is doing rollbacking the DB.  We can
      # only hope that the right thing is being done.
    end

    should "fail when missing the domain name" do
      @params[:domain][:name] = ""
      assert_no_account_created @params
      # Because we are using a transaction around the whole test, we can't
      # test that this specific case is doing rollbacking the DB.  We can
      # only hope that the right thing is being done.
    end
  
    should "fail when the domain name is incorrect" do
      @params[:domain][:name] = "zuly"
      assert_no_account_created @params
      # Because we are using a transaction around the whole test, we can't
      # test that this specific case is doing rollbacking the DB.  We can
      # only hope that the right thing is being done.
    end
  
    should "fail when the expiration date is missing" do
      @params[:account][:expires_at] = ""
      assert_no_account_created @params
    end
  
    should "fail when the expiration date cannot be parsed" do
      @params[:account][:expires_at] = "party"
      assert_no_account_created @params
    end

    should "succeed when all parameters are present and record the data in the DB" do
      assert_difference(Account, :count) { post :create, @params }
  
      assert !assigns(:acct).new_record?
  
      assert_not_nil domain = Domain.find_by_name("want.com"), "New domain created"
      assert_not_nil account = domain.account, "Domain's account referenced"
      assert_not_nil owner = account.owner, "Account's owner referenced"
      assert_equal "Singer, Jon", owner.display_name, "Account owner name"
      assert_equal owner, account.parties.authenticate_with_email_and_password!("jon.singer@want.com", "patent"),
          "Can authenticate using email/password"
  
      assert_template "create"
    end
  end

  protected
  def assert_no_account_created(params, stub_count=0)
    assert_difference Account, :count, stub_count do
      post :create, params
    end

    assert_template "new"
  end
end
