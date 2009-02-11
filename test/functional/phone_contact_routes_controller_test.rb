require File.dirname(__FILE__) + '/../test_helper'
require 'phone_contact_routes_controller'

# Re-raise errors caught by the controller.
class PhoneContactRoutesController; def rescue_action(e) raise e end; end

module PhoneContactRoutesControllerTest
  class UserWithEditPartyPermissionCan < Test::Unit::TestCase
    def setup
      @controller = PhoneContactRoutesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new

      @bob = login_with_permissions!(:bob, :edit_party)
      @phone = @bob.main_phone
      @phone.number = "444-555-6666"
      @phone.save!
    end

    def test_create
      assert_difference PhoneContactRoute, :count, 1 do
        xhr :post, :create, :party_id => @bob.id, :phone => {"1" => {:name => "Office", :number => "+01 72 45 67 89"}}
        assert_response :success
        assert_template "create"
        assert_not_nil @bob.phones(true).find_by_number("+01 72 45 67 89")
      end
    end

    def test_create_with_columns_at_default_values
      xhr :post, :create, :party_id => @bob.id,
          :phone => {"7" => {:number => "111-222-3333", :extension => "Extension"}}
      assert_response :success
      @phone = @bob.phones(true).find_by_number("111-222-3333")
      assert_nil @phone.extension, "Extension"
    end

    def test_show
      get :show, :party_id => @bob.id, :id => @phone.id
      assert_response :success
      assert_template "_phone_contact_route"
      assert_select "\#phone_contact_route_#{@phone.id}_number_edit[url=?]",
          party_phone_path(@bob, @phone)
    end

    def test_update
      assert_difference PhoneContactRoute, :count, 0 do
        xhr :put, :update, :party_id => @bob.id, :id => @phone.id, :phone => {@phone.id.to_s => {:number => "123-456-7890"}}
        assert_response :success
        assert_equal "123-456-7890", @bob.main_phone(true).number
      end
    end

    def test_destroy
      assert_difference PhoneContactRoute, :count, -1 do
        xhr :delete, :destroy, :party_id => @bob.id, :id => @phone.id
        assert_response :success
      end
    end

    def test_get_new_against_existing_party
      get :new, :party_id => @bob.id
      assert_not_nil assigns(:phone)
      assert assigns(:phone).new_record?
      assert_equal @bob, assigns(:phone).routable
      assert_template "_phone_contact_route"
      assert_select "\#new_phone_contact_route_number_edit" do |elems|
        assert_equal 1, elems.size
        assert_nil elems.first["url"], "expected to not find a url attribute on element:\n#{elems.first}"
      end

      assert_select "\#new_phone_contact_route" do
        assert_select "a", /save/i, "Could not find save link in:\n#{@response.body}"
        assert_select "a", /cancel/i, "Could not find cancel link in:\n#{@response.body}"
      end
    end

    def test_get_new_without_party
      get :new
      assert_response :success
      assert_not_nil assigns(:phone)
      assert assigns(:phone).new_record?
      assert_nil assigns(:phone).routable
      assert_template "_phone_contact_route"
      assert_select "#new_phone_contact_route_number_edit" do |elems|
        assert_equal 1, elems.size
        assert_nil elems.first["url"], "expected to not find a url attribute on element:\n#{elems.first}"
      end
    end

    def test_delete_by_clearing_out_the_number_field
      assert_difference PhoneContactRoute, :count, -1 do
        xhr :put, :update, :party_id => @bob.id, :id => @phone.id, :phone => {@phone.id.to_s => {:number => ""}}
      end

      assert_response :success
      assert_template "destroy"
      assert_raises(ActiveRecord::RecordNotFound) { @phone.reload }
    end

    def test_change_name_field_only
      assert_difference PhoneContactRoute, :count, 0 do
        xhr :put, :update, :party_id => @bob.id, :id => @phone.id, :phone => {@phone.id.to_s => {:name => "sentinel"}}
      end

      assert_response :success
      assert_template "update"
      assert_equal "sentinel", @phone.reload.name.downcase
    end
  end

  class UserWithEditOwnAccountPermissionOnlyCan < Test::Unit::TestCase
    def setup
      @controller = PhoneContactRoutesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
  
      @bob = login_with_permissions!(:bob, :edit_own_account)
      @phone = @bob.main_phone
      @phone.number = "444-555-6666"
      @phone.save!
    end

    def test_create_new_phone_through_party
      assert_difference PhoneContactRoute, :count, 1 do
        post :create, :party_id => @bob.id, :phone => {"3" => {:number => "111-222-3333"}}
      end

      assert_response :success
      assert_not_nil @bob.phones(true).find_by_number("111-222-3333")
    end

    def test_update_own_phone_through_party
      put :update, :party_id => @bob.id, :id => @phone.id, :phone => {@phone.id.to_s => {:number => "819-555-1212"}}
      assert_response :success

      @phone.reload
      assert_equal "819-555-1212", @phone.number.downcase
    end

    def test_delete_own_phone_through_party
      assert_difference PhoneContactRoute, :count, -1 do
        delete :destroy, :party_id => @bob.id, :id => @phone.id
      end

      assert_response :success
      assert_template "destroy"
      assert_raises(ActiveRecord::RecordNotFound) { @phone.reload }
    end

    def test_delete_own_phone_directly
      assert_difference PhoneContactRoute, :count, -1 do
        delete :destroy, :id => @phone.id
      end

      assert_response :success
      assert_template "destroy"
      assert_raises(ActiveRecord::RecordNotFound) { @phone.reload }
    end

    def test_not_delete_phone_from_other_party_directly
      @phone = parties(:mary).main_phone
      @phone.number = "555 222 2222"
      @phone.save!
      assert_difference PhoneContactRoute, :count, 0 do
        assert_raises(ActiveRecord::RecordNotFound) do
          delete :destroy, :id => @phone.id
        end

        assert_nothing_raised { @phone.reload }
      end
    end

    def test_not_delete_phone_from_other_party_through_party
      @phone = parties(:mary).main_phone
      @phone.number = "555 222 2222"
      @phone.save!
      assert_difference PhoneContactRoute, :count, 0 do
        assert_raises(ActiveRecord::RecordNotFound) do
          delete :destroy, :party_id => @phone.routable.id, :id => @phone.id
        end

        assert_nothing_raised { @phone.reload }
      end
    end
  end
end
