require File.dirname(__FILE__) + '/../test_helper'
require 'parties_controller'

# Re-raise errors caught by the controller.
class PartiesController; def rescue_action(e) raise e end; end

class PartiesControllerTest < Test::Unit::TestCase
  def setup
    @controller = PartiesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @account = Account.find(:first)
  end

  context "An authenticated party" do
    setup do
      @bob = login_with_no_permissions!(:bob)
    end

    context "with no permissions" do
      should "not GET #new" do
        get :new
        assert_response :success
        assert_template "unauthorized"
      end

      should "not GET #general on an existing party" do
        get :general, :id => @bob.id
        assert_response :success
        assert_template "unauthorized"
      end

      should "not PUT #update on an existing party" do
        put :update, :id => @bob.id, :party => {:last_name => "Mangore"}
        assert_response :success
        assert_template "unauthorized"
      end

      should "not POST #create" do
        post :create, :party => {:last_name => "Mangore", :first_name => "Bitty"}
        assert_response :success
        assert_template "unauthorized"
      end

      should "not DELETE #destroy" do
        delete :destroy, :id => @bob.id
        assert_response :success
        assert_template "unauthorized"
      end
    end

    context "with the :edit_own_contacts_only permission" do
      setup do
        @bob.append_permissions(:edit_own_contacts_only)
        @mine = @account.parties.create!(:last_name => "Kilgore", :created_by => @bob)
        @another_party = @account.parties.create!(:last_name => "Bobby")
      end

      should "GET /admin/parties;new" do
        get :new
        assert_response :success
        assert_template "new"
      end

      should "GET /admin/parties/__ID__;general on my party" do
        get :general, :id => @mine.id
        assert_response :success
        assert_template "notes" # We open the notes panel by default
      end

      should "not GET /admin/parties/__ID__;general of another party" do
        get :general, :id => @another_party.id
        assert_response :success
        assert_template "unauthorized"
      end

      should "POST /admin/parties with {:last_name => 'Mangore', :first_name => 'Bitty'}" do
        post :create, :party => {:last_name => "Mangore", :first_name => "Bitty"}
        assert_response :redirect
        assert_redirected_to general_party_path(assigns(:party))
      end

      should "PUT /admin/parties/__ID__ on my party" do
        put :update, :id => @mine.id, :party => {:last_name => "Kilgore"}
        assert_not_nil assigns(:party)
        assert_response :redirect
        assert_redirected_to party_path(assigns(:party))
      end

      should "not PUT /admin/parties/__ID__ on another party" do
        put :update, :id => @another_party.id, :party => {:last_name => "Kilgore"}
        assert_response :success
        assert_template "unauthorized"
      end

      should "not DELETE /admin/parties/__ID__ (can't destroy self)" do
        delete :destroy, :id => @bob.id
        assert_response :success
        assert_template "unauthorized"
      end

      should "DELETE /admin/parties/__ID__ on my party" do
        delete :destroy, :id => @mine.id
        assert_response :redirect
        assert_redirected_to parties_path
      end

      should "not DELETE /admin/parties/__ID__ on another party" do
        delete :destroy, :id => @another_party.id
        assert_response :success
        assert_template "unauthorized"
      end
      
      should "not see another party in the contact list" do
        xhr :get, :index, :format => "json"
        assert_not_include @another_party.id, assigns(:parties).map(&:id)
      end
    end

    context "with the :edit_own_account permission" do
      setup do
        @bob.append_permissions(:edit_own_account)
        @another_party = @account.parties.create!(:last_name => "Bobby")
      end

      should "not GET /admin/parties;new" do
        get :new
        assert_response :success
        assert_template "unauthorized"
      end

      should "GET /admin/parties/__ID__;general" do
        get :general, :id => @bob.id
        assert_response :success
        assert_template "notes" # We open the notes panel by default
      end

      should "not GET /admin/parties/__ID__;general of another party" do
        get :general, :id => @another_party.id
        assert_response :success
        assert_template "unauthorized"
      end

      should "not POST /admin/parties with {:last_name => 'Mangore', :first_name => 'Bitty'}" do
        post :create, :party => {:last_name => "Mangore", :first_name => "Bitty"}
        assert_response :success
        assert_template "unauthorized"
      end

      should "PUT /admin/parties/__ID__" do
        put :update, :id => @bob.id, :party => {:last_name => "Kilgore"}
        assert_not_nil assigns(:party)
        assert_equal @bob, assigns(:party)
        assert_response :redirect
        assert_redirected_to party_path(assigns(:party))
      end

      should "not PUT /admin/parties/__ID__ on another party" do
        put :update, :id => @another_party.id, :party => {:last_name => "Kilgore"}
        assert_response :success
        assert_template "unauthorized"
      end

      should "not DELETE /admin/parties/__ID__ (can't destroy self)" do
        delete :destroy, :id => @bob.id
        assert_response :success
        assert_template "unauthorized"
      end

      should "not DELETE /admin/parties/__ID__ on another party" do
        delete :destroy, :id => @another_party.id
        assert_response :success
        assert_template "unauthorized"
      end
    end

    context "with the :edit_party permission" do
      setup do
        @bob.append_permissions(:edit_party)
        @another_party = @account.parties.create!(:last_name => "Bobby")
      end

      should "GET /admin/parties;new" do
        get :new
        assert_response :success
        assert_template "new"
      end

      should "GET /admin/parties/__ID__;general" do
        get :general, :id => @bob.id
        assert_response :success
        assert_template "notes" # We open the notes panel by default
      end

      should "GET /admin/parties/__ID__;general of another party" do
        get :general, :id => @another_party.id
        assert_response :success
        assert_template "notes" # We open the notes panel by default
      end

      should "POST /admin/parties with {:last_name => 'Mangore', :first_name => 'Bitty'}" do
        post :create, :party => {:last_name => "Mangore", :first_name => "Bitty"}
        assert_response :redirect
        assert_redirected_to general_party_path(assigns(:party))
      end

      should "PUT /admin/parties/__ID__" do
        put :update, :id => @bob.id, :party => {:last_name => "Kilgore"}
        assert_response :redirect
        assert_redirected_to party_path(assigns(:party))
      end

      should "PUT /admin/parties/__ID__ on another party" do
        put :update, :id => @another_party.id, :party => {:last_name => "Kilgore"}
        assert_response :redirect
        assert_redirected_to party_path(assigns(:party))
      end

      should "DELETE /admin/parties/__ID__ (can't destroy self)" do
        delete :destroy, :id => @bob.id
        assert_response :redirect
        assert_redirected_to party_path(@bob)
      end

      should "DELETE /admin/parties/__ID__ on another party" do
        delete :destroy, :id => @another_party.id
        assert_response :redirect
        assert_redirected_to parties_path
      end
    end
  end

  class UserWithEditPartyPermissionCan < Test::Unit::TestCase
    def setup
      @controller = PartiesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
  
      @bob = login_with_permissions!(:bob, :edit_party, :edit_party_security)
      @party = @account.parties.create!
    end

    def test_sees_only_this_accounts_groups_on_security_page
      @foreign_account = create_new_account
      @terminators = @foreign_account.groups.create!(:name => "Terminators")
      get :security, :id => @bob.id

      deny assigns(:available_groups).include?(@terminators),
          "Terminators group should not be visible from another account"
    end

    def test_not_archive_himself
      assert_difference Party, :count_without_archived_scope, 0 do
        assert_difference Party, :count, 0 do
          put :archive, :id => @bob.id
          assert_response :redirect
          assert_redirected_to party_path(@bob)
        end
      end

      assert_failure_flash_contains /cannot archive your own record/i
      assert_nothing_raised { @bob.reload }
    end

    def test_archive_another_party
      assert_difference Party, :count_without_archived_scope, 0 do
        assert_difference Party, :count, -1 do
          put :archive, :id => @party.id
          assert_response :redirect
          assert_redirected_to parties_path
        end
      end

      assert_success_flash_contains /was archived/i
      assert_raises(ActiveRecord::RecordNotFound) { @party.reload }
    end

    def test_view_index_with_pagination
      get :index, :show => 1, :page => 2
      assert_response :success
      assert_template "parties/index"
    end
    
    def test_create
      assert_difference @account.parties, :count, 1 do
        post :create, :party => {:last_name => "Oldman"}
      end

      assert_redirected_to general_party_path(assigns(:party))
      assert_equal assigns(:party), @account.parties.find_by_last_name("Oldman")
      assigns(:party).reload
      assert_equal @bob, assigns(:party).created_by, "Created by not set to currently logged in user"
      assert_equal @bob, assigns(:party).updated_by, "Updated by not set to currently logged in user"
    end

    def test_can_create_with_tags_immediately
      assert_difference Party, :count, 1 do
        post :create, :party => {:last_name => "Oldman", :tag_list => "Tag List needs-processing"}
        assert_response :redirect
        assert_redirected_to general_party_path(assigns(:party))
      end

      @party = assigns(:party)
      @party.reload
      assert_equal 1, @party.tags.size
      assert_equal [Tag.find_by_name("needs-processing")], @party.tags
    end

    def test_not_create_party_with_duplicate_email_address
      post :create, :party => {:last_name => "Oldman"},
        :email_address => {"1" => {:email_address => @bob.main_email.email_address}}, 
        :address => {}, :phone => {}, :link => {}
      assert_response :success
      assert_template "new"
    end

    def test_auto_complete
      get :auto_complete, :q => @bob.first_name
      assert_response :success
      assert_template "auto_complete"
      assert_kind_of Array, assigns(:parties)
      assert assigns(:parties).include?(@bob)
    end 

    def test_auto_complete_with_specific_field
      get :auto_complete, :q => @bob.company_name[0 .. -2], :field => "company_name"
      assert_response :success
      assert_kind_of Array, assigns(:parties)
      assert_equal [@bob], assigns(:parties)
    end

    def test_not_auto_complete_when_bad_field
      assert_raises(BadFieldException) do
        get :auto_complete, :q => @bob.company_name[0 .. -2], :field => "kataya"
      end
    end

    def test_update
      assert_difference @account.parties, :count, 0 do
        xhr :put, :update, :id => @party.id, :party => {:last_name => "Yumi"}
      end

      assert_response :success
      assert_template "update.rjs"
      @party.reload
      assert_equal "Yumi", @party.last_name
      assert_equal @bob, @party.updated_by, "Updated by not set to currently logged in user"
    end
  
    def test_get_index_with_q_and_one_search_result_only_to_find_redirected_to_party
      assert_equal 1, @account.parties.count(:all, :conditions => ["first_name LIKE ?", "%#{@bob.first_name}%"])
      get :index, :q => @bob.first_name
      assert_response :redirect
      assert_redirected_to party_path(@bob)
    end

    def test_add_one_address_on_new_party
      assert_difference AddressContactRoute, :count, 1 do
        post :create, :party => {:first_name => "Francois"},
            :address => {"99" => {:line1 => "some address"}}
      end

      assert_response :redirect
      @party =  assigns(:party).reload
      assert_not_nil @party.addresses.find_by_line1("some address")
    end

    def test_add_two_address_on_new_party
      assert_difference AddressContactRoute, :count, 2 do
        post :create, :party => {:first_name => "Francois"},
            :address => { "99" => {:line1 => "some address"},
                          "100" => {:line1 => "another address"}}
      end

      assert_response :redirect
      @party =  assigns(:party).reload
      assert_not_nil @party.addresses.find_by_line1("some address")
      assert_not_nil @party.addresses.find_by_line1("another address")
    end

    def test_add_no_links_on_new_party_when_url_blank
      assert_difference LinkContactRoute, :count, 0 do
        post :create, :party => {:first_name => "Francois"},
            :link => {"100" => {:url => ""}}
      end

      assert_response :redirect
    end

    def test_add_one_link_on_new_party
      assert_difference LinkContactRoute, :count, 1 do
        post :create, :party => {:first_name => "Francois"},
            :link => {"100" => {:url => "blog.company.com"}}
      end

      assert_response :redirect
      @party =  assigns(:party).reload
      assert_not_nil @party.links.find_by_url("blog.company.com")
    end

    def test_add_two_links_on_new_party
      assert_difference LinkContactRoute, :count, 2 do
        post :create, :party => {:first_name => "Francois"},
            :link => {"100" => {:url => "blog.company.com"},
                      "101" => {:url => "corporate.company.com"}}
      end

      assert_response :redirect
      @party =  assigns(:party).reload
      assert_not_nil @party.links.find_by_url("blog.company.com")
      assert_not_nil @party.links.find_by_url("corporate.company.com")
    end

    def test_add_no_email_address_on_new_party_when_address_blank
      assert_difference EmailContactRoute, :count, 0 do
        post :create, :party => {:first_name => "Francois"},
            :email_address => {"100" => {:email_address => ""}}
      end

      assert_response :redirect
    end

    def test_add_one_email_address_on_new_party
      assert_difference EmailContactRoute, :count, 1 do
        post :create, :party => {:first_name => "Francois"},
            :email_address => {"100" => {:email_address => "me@company.com"}}
      end

      assert_response :redirect
      @party =  assigns(:party).reload
      assert_not_nil @party.email_addresses.find_by_address("me@company.com")
    end

    def test_add_two_email_addresses_on_new_party
      assert_difference EmailContactRoute, :count, 2 do
        post :create, :party => {:first_name => "Francois"},
            :email_address => { "100" => {:email_address => "me@company.com"},
                                "101" => {:name => "Office", :email_address => "office@company.com"}}
      end

      assert_response :redirect
      @party =  assigns(:party).reload
      assert_not_nil @party.email_addresses.find_by_email_address("me@company.com")
      assert_not_nil @party.email_addresses.find_by_name_and_email_address("Office", "office@company.com")
    end

    def test_add_no_phone_on_new_party_when_number_blank
      assert_difference PhoneContactRoute, :count, 0 do
        post :create, :party => {:first_name => "Francois"},
            :phone => {"200" => {:number => "", :extension => "231"}}
      end

      assert_response :redirect
    end

    def test_add_one_phone_on_new_party
      assert_difference PhoneContactRoute, :count, 1 do
        post :create, :party => {:first_name => "Francois"},
            :phone => {"200" => {:number => "444-555-1212", :extension => "231"}}
      end

      assert_response :redirect
      @party =  assigns(:party).reload
      assert_not_nil @party.phones.find_by_number_and_extension("444-555-1212", "231")
    end

    def test_add_two_phones_on_new_party
      assert_difference PhoneContactRoute, :count, 2 do
        post :create, :party => {:first_name => "Francois"},
            :phone => { "200" => {:number => "444-555-1212", :extension => "231"},
                        "201" => {:number => "333-222-1111", :extension => ""}}
      end

      assert_response :redirect
      @party =  assigns(:party).reload
      assert_not_nil @party.phones.find_by_number_and_extension("444-555-1212", "231")
      assert_not_nil @party.phones.find_by_number_and_extension("333-222-1111", "")
    end

    def test_create_with_default_values
      assert_difference Party, :count, 1 do
        assert_difference ContactRoute, :count, 0 do
          post :create, :party => {:first_name => "John", :tag_list => "Tag List", :company_name => "Company Name"},
              :address => {"1" => {:name => "Main", :line1 => "Line1", :city => "City", :state => "State", :country => "Country", :zip => "Zip"}},
              :email_address => {"2" => {:name => "Main", :email_address => "Email Address"}},
              :phone => {"3" => {:name => "Office", :number => "Number", :extension => "Extension"}},
              :link => {"4" => {:name => "Alternate", :url => "Url"}}
        end
      end

      @party = assigns(:party).reload
      assert @party.company_name.blank?, "Company name was assigned, expected nil or blank: #{@party.company_name.inspect}"
      assert @party.tag_list.blank?, "Tag list was assigned, expected nil or blank: #{@party.tag_list.inspect}"
      assert_equal 0, @party.contact_routes.size
    end

    def test_update_notes_using_javascript
      put :update, :id => @party.id, "party" => {"notes" => "bla di bla"}, :format => "js"
      assert_response :success
      assert_template "parties/update.rjs"
      assert_equal "bla di bla", @party.reload.notes
    end

    def test_prevent_tags_bleeding_between_accounts
      account_one = create_new_account
      account_two = create_new_account
      Tag.delete_all
      assert_difference Tag, :count, 5 do
        assert account_one.parties.create!(:first_name => "Account one party", :tag_list => "wup di do")
        assert account_two.parties.create!(:first_name => "Account two party", :tag_list => "nya ha")
      end
      get :general, :id => @bob.id
      common_tags = assigns(:common_tags)
      for e in common_tags
        assert_nil %w(wup di do nya ha).index(e.name)
      end           
    end
  end
  
  class UserWithEditOwnAccountPermissionOnlyCan < Test::Unit::TestCase
    def setup
      @controller = PartiesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
  
      @bob = login_with_permissions!(:bob, :edit_own_account)
      assert !@bob.can?(:edit_party)
      @party = @account.parties.create!
    end

    def test_general_page_does_not_offer_ability_to_edit_tag_list
      get :general, :id => @bob.id
      assert_response :success
      assert_select "textarea[name=?]", "party[tag_list]", :count => 0
    end

    def test_general_page_does_not_offer_ability_to_edit_referred_by
      get :general, :id => @bob.id
      assert_response :success
      assert_select "input[name=?]", "auto_complete[referred_by]", :count => 0
      assert_select "input[name=?]", "party[referred_by_id]", :count => 0
    end

    def test_only_update_their_allowed_fields
      @bob.tag_list = ""
      @bob.notes = "some compromising notes"
      @bob.save!
      original_tag_list, original_notes = @bob.reload.tag_list, @bob.notes
      
      put :update, :id => @bob.id,
          :party => {:notes => "removing compromising notes",
            :referred_by_id => @party.id.to_s, :first_name => "Johnny"}

      assert_response :redirect

      @bob.reload

      assert_equal original_notes, @bob.notes, "Whitelist let through #notes"
      assert_nil @bob.referred_by, "Whitelist let through #referred_by_id"
    end

    def test_not_create
      assert_difference @account.parties, :count, 0 do
        post :create, :party => {:last_name => "Yumi"}
        assert_template "shared/rescues/unauthorized"
      end
    end
  
    def test_not_auto_complete
      get :auto_complete, :q => @bob.first_name
      assert_template "shared/rescues/unauthorized"
    end
  
    def test_not_view_index
      get :index
      assert_template "shared/rescues/unauthorized"
    end
  
    def test_not_view_other_party
      get :general, :id => @party.id
      assert_template "shared/rescues/unauthorized"
    end
  
    def test_not_update_other_party
      assert_equal '', @party.reload.last_name
      put :update, :id => @party.id, :party => {:last_name => "Tumble"}
      assert_template "shared/rescues/unauthorized"
      assert_equal '', @party.reload.last_name
    end
  
    def test_not_destroy_other_party
      assert_difference @account.parties, :count, 0 do
        delete :destroy, :id => @party.id
        assert_template "shared/rescues/unauthorized"
        assert_nothing_raised { @account.parties.find(@party.id) }
      end
    end
  
    def test_view_own_party
      get :general, :id => @bob.id
      assert_response :success
      #general now redirects to notes
      assert_template "notes"
    end
  
    def test_update_own_party
      put :update, :id => @bob.id, :party => {:last_name => "Yumi"}
      assert_redirected_to party_path(@bob)
      assert_equal "Yumi", @bob.reload.last_name
    end
  
    def test_not_delete_own_account
      assert_difference @account.parties, :count, 0 do
        delete :destroy, :id => @bob.id
        assert_template "shared/rescues/unauthorized"
        assert_nothing_raised { @account.parties.find(@bob.id) }
      end
    end

    def test_change_his_password_when_the_right_old_password_is_provided
      salt, hash = @bob.password_salt, @bob.password_hash
      put :update, :id => @bob.id, :party => {:password => "blabla123", :password_confirmation => "blabla123", :old_password => "test"}
      @bob.reload
      assert_not_equal [salt, hash], [@bob.password_salt, @bob.password_hash],
          "Password hash/salt should have changed"
      assert_nothing_raised { Party.authenticate_with_account_email_and_password!(@account, @bob.main_email.address, "blabla123") }
    end

    def test_keep_his_password_when_a_bad_old_password_is_provided
      salt, hash = @bob.password_salt, @bob.password_hash
      put :update, :id => @bob.id, :party => {:password => "blabla123", :password_confirmation => "blabla123", :old_password => "not-my-password"}
      @bob.reload
      assert_equal [salt, hash], [@bob.password_salt, @bob.password_hash],
          "Password hash & salt should NOT have changed"
      assert_nothing_raised { Party.authenticate_with_account_email_and_password!(@account, @bob.main_email.address, "test") }
    end

    def test_keep_his_password_when_the_confirmation_does_not_match
      salt, hash = @bob.password_salt, @bob.password_hash
      put :update, :id => @bob.id, :party => {:password => "blabla123", :password_confirmation => "not-the-same", :old_password => "test"}
      @bob.reload
      assert_equal [salt, hash], [@bob.password_salt, @bob.password_hash],
          "Password hash & salt should NOT have changed"
      assert_nothing_raised { Party.authenticate_with_account_email_and_password!(@account, @bob.main_email.address, "test") }
    end

    def test_keep_his_password_when_password_blank
      salt, hash = @bob.password_salt, @bob.password_hash
      put :update, :id => @bob.id, :party => {:password => "", :password_confirmation => "", :old_password => "test"}
      @bob.reload
      assert_equal [salt, hash], [@bob.password_salt, @bob.password_hash],
          "Password hash & salt should NOT have changed"
    end
  end
  
  class UnauthenticatedUserCan < Test::Unit::TestCase
    def setup
      @controller = PartiesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
  
      @bob = parties(:bob)
    end
  
    def test_see_forgot_password_form
      get :forgot_password
      assert_response :success
      assert_template "forgot_password"
      assert_select "form[action=?]", reset_password_parties_path do
        assert_select "input[type=text][name=?]", "email[email_address]"
      end
    end
  
    def test_ask_to_reset_password
      PartyNotification.expects(:deliver_password_reset)
      post :reset_password, :email => {:email_address => @bob.main_email.address}
      assert_redirected_to new_session_path
      old_password_hash = @bob.password_hash
      assert_not_equal old_password_hash, @bob.reload.password_hash
    end
  end

  class PartyRegistrationTest < Test::Unit::TestCase
    def setup
      @controller = PartiesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new  
    end

    def test_register
      get :register
      assert_response :success
      assert_template "register"
      assert_select "form[action$=?][method=post] input[type=text][name=?]", signup_parties_path, "email_address[email_address]"
    end
  end

  class PartySignupTest < Test::Unit::TestCase
    def setup
      @controller = PartiesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new  

      @party = mock("new_party")
      @party.stubs(:id).returns(483)
      @party.stubs(:errors).returns(Party.new.errors)
    end

    def test_signup_fails_with_invalid_record
      Party.expects(:signup!).with do |args|
        args.kind_of?(Hash) && args[:email_address] == {"email_address" => "invalid-email"} && args[:party] == {"tag_list" => ""} \
                            && args[:confirmation_url].kind_of?(Proc) 
      end.raises(ActiveRecord::RecordInvalid.new(Party.new))

      post :signup, :email_address => {:email_address => "invalid-email"}, :party => {:tag_list => ""}
      assert_response :success
      assert_template "register"
    end

    def test_signup_with_data
      party = mock("new_party")
      party.stubs(:id).returns(910)
      Party.expects(:signup!).with do |args|
        args.kind_of?(Hash) && args[:email_address] == {"email_address" => ""} && args[:party] == {"first_name" => "bla"} \
                            && args[:confirmation_url].kind_of?(Proc) 
      end.returns(party)
      @controller.stubs(:confirm_party_url).with(party).returns(:confirmation_party_url)

      post :signup, :party => {:first_name => "bla"}, :email_address => {:email_address => ""}
      assert_response :success
      assert_template "signup"
    end
  end

  class AttemptingToConfirmAPartyTest < Test::Unit::TestCase
    def setup
      @controller = PartiesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new  

      Party.stubs(:find).returns(@party = mock("unconfirmed_party"))
      @party.stubs(:id).returns(231)
      @party.stubs(:confirmation_token).returns("confirmation_token")
      @party.stubs(:password).returns(nil)
      @party.stubs(:password_confirmation).returns(nil)
      @party.stubs(:first_name).returns(nil)
      @party.stubs(:last_name).returns(nil)
      @party.stubs(:new_record?).returns(false)
      @party.stubs(:errors).returns(Party.new.errors)
    end

    def test_with_a_correct_token_renders_confirm_and_hides_code_field
      get :confirm, :id => @party.id, :code => "4234"
      assert_response :success
      assert_template "confirm"

      assert_equal "4234", assigns(:code), "Confirmation token provided in params was not made available to the view"
      assert_equal @party, assigns(:party), "Party being confirmed was not made available to the view"

      assert_select "form[action$=?]", authorize_party_path(@party) do
        assert_select "input[type=hidden][name=code][value=?]", "4234"
        assert_select "input[type=submit]"
      end
    end

    def test_without_a_token_shows_input_field_for_code
      get :confirm, :id => @party.id
      assert_response :success
      assert_template "confirm"

      assert_select "form[action$=?]", authorize_party_path(@party) do
        assert_select "input[type=text][name=code]", false
        assert_select "input[type=submit]"
      end
    end

    def test_from_another_account_should_report_a_missing_url
      @controller.stubs(:current_account).returns(account_proxy = mock("account proxy"))
      account_proxy.stubs(:parties).returns(parties_proxy = mock("parties proxy"))
      parties_proxy.expects(:find).with(@party.id.to_s).raises(ActiveRecord::RecordNotFound)
      account_proxy.expects(:get_config).with(:favicon_url).returns("/")
      account_proxy.expects(:get_config).with(:logo_url).returns("/")      

      get :confirm, :id => @party.id
      assert_response :missing
      assert_template "bad_token_or_user"
    end
  end

  class AuthorizingAPartyTest < Test::Unit::TestCase
    def setup
      @controller = PartiesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new  

      @account = Account.find(:first)

      @party = mock("unconfirmed_party")
      @party.stubs(:id).returns(231)
      @party.stubs(:confirmation_token).returns("confirmation_token")
      @party.stubs(:password).returns(nil)
      @party.stubs(:password_confirmation).returns(nil)
      @party.stubs(:first_name).returns(nil)
      @party.stubs(:last_name).returns(nil)
      @party.stubs(:new_record?).returns(false)
      @party.stubs(:destroyed?).returns(false)
      @party.stubs(:errors).returns(Party.new.errors)
    end

    def test_with_correct_data_and_a_return_to_parameter_redirects_to_the_return_to_parameter
      Party.expects(:find).with do |id, options|
        id == "245" && options[:conditions] =~ /account_id\s*=\s*#{@account.id}/
      end.returns(@party)
      @party.expects(:authorize!).with(:attributes => {"first_name" => "Francois"}, :confirmation_token => "6354").returns(true)
      @party.stubs(:login!)
      put :authorize, :id => "245", :party => {:first_name => "Francois"}, :code => "6354", :return_to => "http://here.com/"

      assert_response :redirect
      assert_redirected_to "http://here.com/"
      assert_success_flash_contains /successfully authorized/
    end

    def test_with_correct_data_redirects_to_the_forums
      #instead of redirecting new users to the dashboard, we are redirecting them to the forums
      Party.expects(:find).with do |id, options|
        id == "231" && options[:conditions] =~ /account_id\s*=\s*#{@account.id}/
      end.returns(@party)
      @party.expects(:authorize!).with(:attributes => {"first_name" => "Francois"}, :confirmation_token => "9187").returns(true)
      @controller.expects(:current_user=).with(@party)
      put :authorize, :id => "231", :party => {:first_name => "Francois"}, :code => "9187"

      assert_response :redirect
      assert_redirected_to forum_categories_url
      assert_success_flash_contains /successfully authorized/
    end

    def test_with_a_bad_confirmation_token_should_render_bad_token_or_user
      Party.expects(:find).with do |id, options|
        id == "211" && options[:conditions] =~ /account_id\s*=\s*#{@account.id}/
      end.returns(@party)
      @party.expects(:name).returns("Francois")
      @party.expects(:authorize!).with(:attributes => {"first_name" => "Francois"}, :confirmation_token => "9187").raises(XlSuite::AuthenticatedUser::BadAuthentication)
      put :authorize, :id => "211", :party => {:first_name => "Francois"}, :code => "9187"

      assert_response 400
      assert_template "bad_token_or_user"
    end

    def test_with_an_expired_confirmation_token_should_render_confirmation_token_expired
      Party.expects(:find).with do |id, options|
        id == "211" && options[:conditions] =~ /account_id\s*=\s*#{@account.id}/
      end.returns(@party)
      @party.expects(:name).returns("Francois")
      @party.expects(:authorize!).with(:attributes => {"first_name" => "Francois"}, :confirmation_token => "9187").raises(XlSuite::AuthenticatedUser::ConfirmationTokenExpired)
      put :authorize, :id => "211", :party => {:first_name => "Francois"}, :code => "9187"

      assert_response 400
      assert_template "confirmation_token_expired"
    end

    def test_with_an_invalid_record_should_render_confirm_view_again
      Party.expects(:find).with do |id, options|
        id == "211" && options[:conditions] =~ /account_id\s*=\s*#{@account.id}/
      end.returns(@party)
      @party.expects(:name).returns("Francois")
      @party.expects(:authorize!).with(:attributes => {"password" => "a", "password_confirmation" => "not same"},
          :confirmation_token => "9187").raises(ActiveRecord::RecordInvalid.new(Party.new))
      put :authorize, :id => "211", :party => {:password => "a", :password_confirmation => "not same"},
          :code => "9187"

      assert_response 200
      assert_template "confirm"
      assert_equal "9187", assigns(:code), "Code from params not made available to the view"
      assert_equal @party, assigns(:party), "Party being authorized not made available to the view"
    end

    def test_with_an_unknown_user_should_let_the_record_not_found_exception_bubble_through
      Party.expects(:find).with do |id, options|
        id == "211" && options[:conditions] =~ /account_id\s*=\s*#{@account.id}/
      end.raises(ActiveRecord::RecordNotFound)
      assert_raises(ActiveRecord::RecordNotFound) do
        put :authorize, :id => "211", :party => {:first_name => "Francois"}, :code => "9187"
      end
    end

    def test_from_another_account_should_let_the_record_not_found_exception_bubble_through
      @controller.stubs(:current_account).returns(account_proxy = mock("account proxy"))
      account_proxy.stubs(:parties).returns(parties_proxy = mock("parties proxy"))
      parties_proxy.expects(:find).with("211").raises(ActiveRecord::RecordNotFound)

      assert_raises(ActiveRecord::RecordNotFound) do
        put :authorize, :id => "211", :party => {:first_name => "Francois"}, :code => "9187"
      end
    end
  end
end
