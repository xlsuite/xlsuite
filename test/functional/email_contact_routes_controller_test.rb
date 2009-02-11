require File.dirname(__FILE__) + '/../test_helper'
require 'email_contact_routes_controller'

# Re-raise errors caught by the controller.
class EmailContactRoutesController; def rescue_action(e) raise e end; end

module EmailContactRoutesControllerTest
  class UserWithEditPartyPermissionCan < Test::Unit::TestCase
    def setup
      @controller = EmailContactRoutesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new

      @bob = login_with_permissions!(:bob, :edit_party)
      @email = @bob.main_email
      @email.email_address = "bob@nowhere.com"
      @email.save!
    end

    def test_validate_when_address_already_used
      get :validate, :email => {:email_address => @bob.main_email.email_address}
      assert_response :success
      assert_template "email_contact_routes/validate"

      assert_select "ul li", /has already been taken/i, response.body
    end

    def test_validate_when_address_is_unused
      get :validate, :email => {:email_address => "frodo@gamgee.net"}
      assert_response :success
      assert_template "email_contact_routes/validate"

      assert_select "ul li", :count => 0
    end

    def test_validate_with_existing_party_and_address_is_on_party
      get :validate, :id => @bob.main_email.id, :email => {:email_address => @bob.main_email.email_address}
      assert_response :success
      assert_template "email_contact_routes/validate"

      assert_select "ul li", :count => 0
    end

    def test_show
      get :show, :party_id => @bob.id, :id => @email.id
      assert_response :success
      assert_template "_email_contact_route"
      assert_select "\#email_contact_route_#{@email.id}_email_address_edit[url=?]",
          party_email_path(@bob, @email)
    end

    def test_update
      assert_difference EmailContactRoute, :count, 0 do
        xhr :put, :update, :party_id => @bob.id, :id => @email.id, :email_address => {@email.id.to_s => {:email_address => "bobby@here.com"}}
      end

      assert_response :success
      assert_equal "bobby@here.com", @bob.main_email(true).email_address
    end

    def test_destroy
      assert_difference EmailContactRoute, :count, -1 do
        xhr :delete, :destroy, :party_id => @bob.id, :id => @email.id
      end

      assert_response :success
      assert_template "destroy"
    end

    def test_get_new_against_existing_party
      get :new, :party_id => @bob.id
      assert_not_nil assigns(:email_address)
      assert assigns(:email_address).new_record?
      assert_equal @bob, assigns(:email_address).routable
      assert_template "_email_contact_route"
      assert_select "#new_email_contact_route_email_address_edit" do |elems|
        assert_equal 1, elems.size
        assert_nil elems.first["url"], "expected to not find a url attribute on element:\n#{elems.first}"
      end
    end

    def test_get_new_without_party
      get :new
      assert_response :success
      assert_not_nil assigns(:email_address)
      assert assigns(:email_address).new_record?
      assert_nil assigns(:email_address).routable
      assert_template "_email_contact_route"
      assert_select "#new_email_contact_route_email_address_edit" do |elems|
        assert_equal 1, elems.size
        assert_nil elems.first["url"], "expected to not find a url attribute on element:\n#{elems.first}"
      end
    end

    def test_create
      assert_difference EmailContactRoute, :count, 1 do
        xhr :post, :create, :party_id => @bob.id, :email_address => {"4" => {:name => "Office", :email_address => "john@template.com"}}
      end

      assert_response :success
      assert_template "create"
      assert_not_nil @bob.email_addresses(true).find_by_address("john@template.com")
    end

    def test_create_with_invalid_address
      assert_difference EmailContactRoute, :count, 0 do
        xhr :post, :create, :party_id => @bob.id, :email_address => {"4" => {:email_address => "john@t"}}
      end

      assert_response :success
      assert_template "error"
    end

    def test_update_with_invalid_address
      assert_difference EmailContactRoute, :count, 0 do
        xhr :post, :create, :party_id => @bob.id, :id => @bob.main_email.id,
            :email_address => {@bob.main_email.id.to_s => {:email_address => "john@t"}}
      end

      assert_response :success
      assert_template "error"
    end

    def test_delete_by_clearing_out_the_address_field
      assert_difference EmailContactRoute, :count, -1 do
        xhr :put, :update, :party_id => @bob.id, :id => @email.id, :email_address => {@email.id.to_s => {:email_address => ""}}
      end

      assert_response :success
      assert_template "destroy"
      assert_raises(ActiveRecord::RecordNotFound) { @email.reload }
    end

    def test_change_name_field_only
      assert_difference EmailContactRoute, :count, 0 do
        xhr :put, :update, :party_id => @bob.id, :id => @email.id, :email_address => {@email.id.to_s => {:name => "sentinel"}}
      end

      assert_response :success
      assert_template "update"
      assert_equal "sentinel", @email.reload.name.downcase
    end
  end

  class UserWithEditOwnAccountPermissionOnlyCan < Test::Unit::TestCase
    def setup
      @controller = EmailContactRoutesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
  
      @bob = login_with_permissions!(:bob, :edit_own_account)
      @email = @bob.main_email
      @email.email_address = "bob@nowhere.com"
      @email.save!
    end

    def test_create_new_email_through_party
      assert_difference EmailContactRoute, :count, 1 do
        post :create, :party_id => @bob.id, :email_address => {"5" => {:email_address => "bob@now.com"}}
      end

      assert_response :success
      assert_not_nil @bob.email_addresses(true).find_by_address("bob@now.com")
    end

    def test_update_own_email_through_party
      put :update, :party_id => @bob.id, :id => @email.id, :email_address => {@email.id.to_s => {:email_address => "bob@thissite.com"}}
      assert_response :success

      @email.reload
      assert_equal "bob@thissite.com", @email.email_address.downcase
    end

    def test_delete_own_email_through_party
      assert_difference EmailContactRoute, :count, -1 do
        delete :destroy, :party_id => @bob.id, :id => @email.id
      end

      assert_response :success
      assert_template "destroy"
      assert_raises(ActiveRecord::RecordNotFound) { @email.reload }
    end

    def test_delete_own_email_directly
      assert_difference EmailContactRoute, :count, -1 do
        delete :destroy, :id => @email.id
      end

      assert_response :success
      assert_template "destroy"
      assert_raises(ActiveRecord::RecordNotFound) { @email.reload }
    end

    def test_not_delete_email_from_other_party_directly
      @email = parties(:mary).main_email
      @email.email_address = "mary@nowhere.com"
      @email.save!
      assert_difference EmailContactRoute, :count, 0 do
        assert_raises(ActiveRecord::RecordNotFound) do
          delete :destroy, :id => @email.id
        end

        assert_nothing_raised { @email.reload }
      end
    end

    def test_not_delete_email_from_other_party_through_party
      @email = parties(:mary).main_email
      @email.email_address = "mary@nowhere.com"
      @email.save!
      assert_difference EmailContactRoute, :count, 0 do
        assert_raises(ActiveRecord::RecordNotFound) do
          delete :destroy, :party_id => @email.routable.id, :id => @email.id
        end

        assert_nothing_raised { @email.reload }
      end
    end
  end
end
