require "#{File.dirname(__FILE__)}/../test_helper"

class PartiesRegistrationTest < ActionController::IntegrationTest
  def setup
    ActionMailer::Base.deliveries = @emails = []
    @account = Account.find(:first)
    
    @account.layouts.create!(:title => "HTML", :body => "{{ page.body }}", :author => parties(:bob))
    @account.pages.create!(:title => "Return to", :fullslug => "signup/errors", :body => "There were errors during signup", :status => "published", :layout => "HTML", :creator => parties(:bob))
    @account.pages.create!(:title => "Subscribed", :fullslug => "signup/success", :body => "You have signed up!", :status => "published", :layout => "HTML", :creator => parties(:bob))
    @account.pages.create!(:title => "Next", :fullslug => "signup/wait", :body => "Please check your email", :status => "published", :layout => "HTML", :creator => parties(:bob))
    @account.pages.create!(:title => "Confirm", :fullslug => "signup/confirm", :body => "Please fill out the form", :status => "published", :layout => "HTML", :creator => parties(:bob))
    host! @account.domains.find(:first).name
  end

  context "A new user" do
    should "be able to register for a login" do
      get_register_page
    
      assert_difference ActionMailer::Base.deliveries, :size, 1 do
        post signup_parties_url, :email_address => {:email_address => "sandborn@test.com"}, 
                                 :return_to => "/signup/errors", :signed_up => "/signup/success", :next => "/signup/wait", :confirm => "/signup/confirm"
        @party = assigns(:party)
        assert_response :redirect
        assert_redirected_to "/signup/wait"
      end
    
      @party.reload
      
      assert_not_nil @party.confirmation_token, "Confirmation token should have been set"
      assert_not_nil @party.confirmation_token_expires_at, "Confirmation token expiration should have been set"
      deny @party.confirmed, "Party should not have been confirmed"
      assert_nil @party.password_hash, "No password should have been assigned" 
    
      confirm_url = confirm_party_url(:id => @party, :code => @party.confirmation_token, :return_to => "/signup/errors", :signed_up => "/signup/success", :confirm => "/signup/confirm")
      @email = @emails.first
      
      assert @email.body.include?(confirm_url),
          "Sent E-Mail does not contain a reference to the confirmation URL"

      get confirm_url
      assert_response :redirect
      assert_redirected_to "/signup/confirm?signed_up=/signup/success&code=#{@party.confirmation_token}&gids="
    
      post authorize_party_url(@party), :code => @party.confirmation_token, :_method => "put",
          :party => {:first_name => "Francois", :password => "password", :password_confirmation => "password"},
          :signed_up => "/signup/success"
      assert_response :redirect
      assert_redirected_to "/signup/success"
    
      @party.reload
      assert_not_nil @party.last_logged_in_at, "Party not logged in"
      assert_not_nil @party.password_hash, "Password not assigned"
      assert_equal @party, Party.authenticate_with_account_email_and_password!(Account.find(:first), "sandborn@test.com", "password"),
          "Could not authenticate with correct email & password"
    
      get general_party_path(@party)
      assert_response :success, "Party was not automatically logged in during authorization"

    end

    should "be able to register for a group and a login" do
      get_register_page
    
      assert_difference ActionMailer::Base.deliveries, :size, 1 do
        post signup_parties_url, :email_address => {:email_address => "sandborn@test.com"}, :party => {:group_ids => "2,3"}, 
                                 :return_to => "/signup/errors", :signed_up => "/signup/success", :next => "/signup/wait", :confirm => "/signup/confirm"
        @party = assigns(:party)
        assert_response :redirect
        assert_redirected_to "/signup/wait"
      end
    
      @party.reload
      assert_equal @party.groups.map(&:id).sort, [2,3]
      
      assert_not_nil @party.confirmation_token, "Confirmation token should have been set"
      assert_not_nil @party.confirmation_token_expires_at, "Confirmation token expiration should have been set"
      deny @party.confirmed, "Party should not have been confirmed"
      assert_nil @party.password_hash, "No password should have been assigned" 
    
      confirm_url = confirm_party_url(:id => @party, :code => @party.confirmation_token, :return_to => "/signup/errors", :signed_up => "/signup/success", :confirm => "/signup/confirm", :gids => "2,3")
      @email = @emails.first
    
      assert @email.body.include?(confirm_url),
          "Sent E-Mail does not contain a reference to the confirmation URL"
    
      get confirm_url
      assert_response :redirect
      assert_redirected_to "/signup/confirm?signed_up=/signup/success&code=#{@party.confirmation_token}&gids=2,3"
    
      post authorize_party_url(@party), :code => @party.confirmation_token, :_method => "put",
          :party => {:first_name => "Francois", :password => "password", :password_confirmation => "password"},
          :signed_up => "/signup/success"
      assert_response :redirect
      assert_redirected_to "/signup/success"
    
      @party.reload
      assert_not_nil @party.last_logged_in_at, "Party not logged in"
      assert_not_nil @party.password_hash, "Password not assigned"
      assert_equal @party, Party.authenticate_with_account_email_and_password!(Account.find(:first), "sandborn@test.com", "password"),
          "Could not authenticate with correct email & password"
    
      get general_party_path(@party)
      assert_response :success, "Party was not automatically logged in during authorization"

    end
    
    should "be not be able to register for a non-existent group" do
      get_register_page
    
      assert_difference Party, :count, 0 do
        assert_difference ActionMailer::Base.deliveries, :size, 0 do
          post signup_parties_url, :email_address => {:email_address => "sandborn@test.com"}, :party => {:group_ids => "10"}, 
                                   :return_to => "/signup/errors", :signed_up => "/signup/success", :next => "/signup/wait", :confirm => "/signup/confirm"
          @party = assigns(:party)
          assert_warning_flash_contains "Couldn't find Group with ID=10"
          assert_response :redirect
          assert_redirected_to "/signup/errors"
        end
      end
    end
  end

  context "An existing user" do
    setup do
      @p = @account.parties.create!()
      EmailContactRoute.create!(:account => @account, :routable => @p.reload, :email_address => "sandborn@test.com")
    end
    
    context "who is confirmed" do
      setup do
        @p.confirmed = true
        @p.password = "testing"
        @p.groups << Group.find(1)
        @p.save!
      end
      
      should "not be able to register for just a login" do
        get_register_page
      
        assert_difference Party, :count, 0 do
          assert_difference ActionMailer::Base.deliveries, :size, 0 do
            post signup_parties_url, :email_address => {:email_address => "sandborn@test.com"}, 
                                     :return_to => "/signup/errors", :signed_up => "/signup/success", :next => "/signup/wait", :confirm => "/signup/confirm"
            @party = assigns(:party)
            assert_warning_flash_contains "You are already registered"
            assert_response :redirect
            assert_redirected_to "/signup/errors"
          end
        end
      end
      
      should "be able to subscribe to groups he does not belong to" do
        get_register_page
      
        assert_difference Party, :count, 0 do
          assert_difference ActionMailer::Base.deliveries, :size, 1 do
            post signup_parties_url, :email_address => {:email_address => "sandborn@test.com"}, :party => {:group_ids => "1,2,3"},
                                     :return_to => "/signup/errors", :signed_up => "/signup/success", :next => "/signup/wait", :confirm => "/signup/confirm"
            @party = assigns(:party)
            assert_response :redirect
            assert_redirected_to "/signup/wait"
          end
        end
        
        assert_not_nil @party.confirmation_token, "Confirmation token should have been set"
        assert_not_nil @party.confirmation_token_expires_at, "Confirmation token expiration should have been set"
        assert @party.confirmed, "Party should have been confirmed"
      
        subscribe_url = subscribe_party_url(:id => @party, :code => @party.confirmation_token, :return_to => "/signup/errors", 
                                        :signed_up => "/signup/success", :confirm => "/signup/confirm", :gids => "3,1,2")
        @email = @emails.first
        
        assert @email.body.include?(subscribe_url),
            "Sent E-Mail does not contain a reference to the subscribe URL"
        
        assert_equal @party.groups.size, 1
        
        get subscribe_url
        assert_response :redirect
        assert_redirected_to "signup/success?gids=3,1,2"
        assert_equal 3, @party.reload.groups.size
      end
      
      should "not be able to subscribe to groups he already belongs to" do
        get_register_page
      
        assert_difference Party, :count, 0 do
          assert_difference ActionMailer::Base.deliveries, :size, 0 do
            post signup_parties_url, :email_address => {:email_address => "sandborn@test.com"}, :party => {:group_ids => "1"},
                                     :return_to => "/signup/errors", :signed_up => "/signup/success", :next => "/signup/wait", :confirm => "/signup/confirm"
            @party = assigns(:party)
            assert_warning_flash_contains "You already belong to the group #{Group.find(1).name}"
            assert_response :redirect
            assert_redirected_to "/signup/errors"
          end
        end
      end
    end
    
    context "who is unconfirmed" do
      should "be able to register for a login" do
        get_register_page
      
        assert_difference ActionMailer::Base.deliveries, :size, 1 do
          post signup_parties_url, :email_address => {:email_address => "sandborn@test.com"}, 
                                   :return_to => "/signup/errors", :signed_up => "/signup/success", :next => "/signup/wait", :confirm => "/signup/confirm"
          @party = assigns(:party)
          assert_response :redirect
          assert_redirected_to "/signup/wait"
        end
      
        @party.reload
        
        assert_not_nil @party.confirmation_token, "Confirmation token should have been set"
        assert_not_nil @party.confirmation_token_expires_at, "Confirmation token expiration should have been set"
        deny @party.confirmed, "Party should not have been confirmed"
        assert_nil @party.password_hash, "No password should have been assigned" 
      
        confirm_url = confirm_party_url(:id => @party, :code => @party.confirmation_token, :return_to => "/signup/errors", :signed_up => "/signup/success", :confirm => "/signup/confirm")
        @email = @emails.first
  
        assert @email.body.include?(confirm_url),
            "Sent E-Mail does not contain a reference to the confirmation URL"
      
        get confirm_url
        assert_response :redirect
        assert_redirected_to "/signup/confirm?signed_up=/signup/success&code=#{@party.confirmation_token}&gids="
      
        post authorize_party_url(@party), :code => @party.confirmation_token, :_method => "put",
            :party => {:first_name => "Francois", :password => "password", :password_confirmation => "password"},
            :signed_up => "/signup/success"
        assert_response :redirect
        assert_redirected_to "/signup/success"
      
        @party.reload
        assert_not_nil @party.last_logged_in_at, "Party not logged in"
        assert_not_nil @party.password_hash, "Password not assigned"
        assert_equal @party, Party.authenticate_with_account_email_and_password!(Account.find(:first), "sandborn@test.com", "password"),
            "Could not authenticate with correct email & password"
      
        get general_party_path(@party)
        assert_response :success, "Party was not automatically logged in during authorization"
  
      end
  
      should "be able to register for a group and a login" do
        get_register_page
      
        assert_difference ActionMailer::Base.deliveries, :size, 1 do
          post signup_parties_url, :email_address => {:email_address => "sandborn@test.com"}, :party => {:group_ids => "2,3"}, 
                                   :return_to => "/signup/errors", :signed_up => "/signup/success", :next => "/signup/wait", :confirm => "/signup/confirm"
          @party = assigns(:party)
          assert_response :redirect
          assert_redirected_to "/signup/wait"
        end
      
        @party.reload
        assert_equal [2,3], @party.groups.map(&:id).sort
        
        assert_not_nil @party.confirmation_token, "Confirmation token should have been set"
        assert_not_nil @party.confirmation_token_expires_at, "Confirmation token expiration should have been set"
        deny @party.confirmed, "Party should not have been confirmed"
        assert_nil @party.password_hash, "No password should have been assigned" 
      
        confirm_url = confirm_party_url(:id => @party, :code => @party.confirmation_token, :return_to => "/signup/errors", :signed_up => "/signup/success", :confirm => "/signup/confirm", :gids => "2,3")
        @email = @emails.first
        
        assert @email.body.include?(confirm_url),
            "Sent E-Mail does not contain a reference to the confirmation URL"
        
        get confirm_url
        assert_response :redirect
        assert_redirected_to "/signup/confirm?signed_up=/signup/success&code=#{@party.confirmation_token}&gids=2,3"
      
        post authorize_party_url(@party), :code => @party.confirmation_token, :_method => "put",
            :party => {:first_name => "Francois", :password => "password", :password_confirmation => "password"},
            :signed_up => "/signup/success"
        assert_response :redirect
        assert_redirected_to "/signup/success"
      
        @party.reload
        assert_not_nil @party.last_logged_in_at, "Party not logged in"
        assert_not_nil @party.password_hash, "Password not assigned"
        assert_equal @party, Party.authenticate_with_account_email_and_password!(Account.find(:first), "sandborn@test.com", "password"),
            "Could not authenticate with correct email & password"
      
        get general_party_path(@party)
        assert_response :success, "Party was not automatically logged in during authorization"
  
      end
    end
  end

  def test_registration_happy_path
    get_register_page

    assert_difference ActionMailer::Base.deliveries, :size, 1 do
      post signup_parties_url, :email_address => {:email_address => "sandborn@test.com"}
      @party = assigns(:party)
      assert_template "signup"
    end

    @party.reload
    assert_not_nil @party.confirmation_token, "Confirmation token should have been set"
    assert_not_nil @party.confirmation_token_expires_at, "Confirmation token expiration should have been set"
    assert_nil @party.password_hash, "No password should have been assigned" 

    confirm_url = confirm_party_url(:id => @party, :code => @party.confirmation_token)
    @email = @emails.first
    assert_equal confirm_url, @email.to_s[confirm_party_url(:id => @party, :code => @party.confirmation_token)],
        "Sent E-Mail does not contain a reference to the confirmation URL" 
    assert_equal @party.confirmation_token, @email.to_s[@party.confirmation_token],
        "Sent E-Mail does not contain a reference to the confirmation token" 

    get confirm_party_url(@party), :code => @party.confirmation_token
    assert_response :success
    assert_template "parties/confirm"
    assert_select "form[action=?]", authorize_party_path(@party) do
      assert_select "input[type=password][name=?]", "party[password]"
      assert_select "input[type=password][name=?]", "party[password_confirmation]"
      assert_select "input[type=submit]"
    end

    post authorize_party_url(@party), :code => @party.confirmation_token, :_method => "put",
        :party => {:first_name => "Francois", :password => "password", :password_confirmation => "password"},
        :return_to => "http://some.url.in/another-address-space"
    assert_response :redirect
    assert_redirected_to "http://some.url.in/another-address-space"

    @party.reload
    assert_not_nil @party.last_logged_in_at, "Party not logged in"
    assert_not_nil @party.password_hash, "Password not assigned"
    assert_equal @party, Party.authenticate_with_account_email_and_password!(Account.find(:first), "sandborn@test.com", "password"),
        "Could not authenticate with correct email & password"

    get general_party_path(@party)
    assert_response :success, "Party was not automatically logged in during authorization"
  end
  
  def test_attempting_to_foil_confirmation_token_expiry_time
    get_register_page

    assert_difference ActionMailer::Base.deliveries, :size, 1 do
      post signup_parties_url, :email_address => {:email_address => "sandborn@test.com"},
          :confirmation_token_expires_at => 10.days.from_now
      @party = assigns(:party)
      assert_template "signup"
    end

    assert_operator @party.reload.confirmation_token_expires_at, :<, 25.hours.from_now

    assert_difference ActionMailer::Base.deliveries, :size, 1 do
      post signup_parties_url, :email_address => {:email_address => "sandborn2@test.com"},
          :party => {:confirmation_token_expires_at => 10.days.from_now}
      @party = assigns(:party)
      assert_template "signup"
    end

    assert_operator @party.reload.confirmation_token_expires_at, :<, 25.hours.from_now
  end

  def test_attempting_to_foil_confirmation_token
    get_register_page

    assert_difference ActionMailer::Base.deliveries, :size, 1 do
      post signup_parties_url, :email_address => {:email_address => "sandborn@test.com"},
          :confirmation_token => "my-confirmation-token"
      @party = assigns(:party)
      assert_template "signup"
    end

    assert_not_equal "my-confirmation-token", @party.reload.confirmation_token

    assert_difference ActionMailer::Base.deliveries, :size, 1 do
      post signup_parties_url, :email_address => {:email_address => "sandborn2@test.com"},
          :party => {:confirmation_token => "my-confirmation-token"}
      @party = assigns(:party)
      assert_template "signup"
    end

    assert_not_equal "my-confirmation-token", @party.reload.confirmation_token
  end

  protected
  def get_register_page
    get register_parties_url
    assert_response :success
    assert_select "form[method=post][action$=?]", signup_parties_path do
      assert_select "input[type=text][name=?]", "email_address[email_address]"
      assert_select "input[type=submit]"
    end
  end
end
