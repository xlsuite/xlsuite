require File.dirname(__FILE__) + '/../test_helper'
require 'address_contact_routes_controller'

# Re-raise errors caught by the controller.
class AddressContactRoutesController; def rescue_action(e) raise e end; end

module AddressContactRoutesControllerTest
  class UserWithEditPartyPermissionCan < Test::Unit::TestCase
    def setup
      @controller = AddressContactRoutesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
  
      @bob = login_with_permissions!(:bob, :edit_party)
      @address = @bob.main_address
      @address.save!
    end

    def test_create
      assert_difference AddressContactRoute, :count, 1 do
        xhr :post, :create, :party_id => @bob.id, :address => {"7" => {:line1 => "beijing", :country => "CAN"}}
        assert_response :success
        assert_template "create"
        assert_not_nil @bob.addresses(true).find_by_line1("beijing")
      end
    end

    def test_create_with_columns_at_default_values
      Configuration.set(:default_city, nil, @bob.account)
      Configuration.set(:default_state, nil, @bob.account)
      Configuration.set(:default_country, nil, @bob.account)

      xhr :post, :create, :party_id => @bob.id,
          :address => {"7" => {:line1 => "china", :line2 => "Line2", :line3 => "Line3",
              :city => "City", :state => "State", :country => "Country", :zip => "Zip"}}
      assert_response :success
      @address = @bob.addresses(true).find_by_line1("china")
      assert @address.line2.blank?, "Line 2"
      assert @address.line3.blank?, "Line 3"
      assert @address.city.blank?, "City"
      assert @address.state.blank?, "State"
      assert @address.country.blank?, "Country"
      assert @address.zip.blank?, "Zip"
    end

    def test_show
      get :show, :party_id => @bob.id, :id => @address.id
      assert_response :success
      assert_template "_address_contact_route"
      assert_select "\#address_contact_route_#{@address.id}_line1_edit[url=?]",
          "/admin/parties/#{@bob.id}/addresses/#{@address.id}"
    end
  
    def test_update
      assert_difference AddressContactRoute, :count, 0 do
        xhr :put, :update, :party_id => @bob.id, :id => @address.id, :address => {@address.id.to_s => {:line1 => "bingo"}}
        assert_response :success
        assert_equal "Bingo", @bob.main_address(true).line1
      end
    end
  
    def test_destroy
      assert_difference AddressContactRoute, :count, -1 do
        xhr :delete, :destroy, :party_id => @bob.id, :id => @address.id
        assert_response :success
      end
    end

    def test_get_new_against_existing_party
      get :new, :party_id => @bob.id
      assert_not_nil assigns(:address)
      assert assigns(:address).new_record?
      assert_equal @bob, assigns(:address).routable
      assert_template "_address_contact_route"
      assert_select "#new_address_contact_route_line1_edit" do |elems|
        assert_equal 1, elems.size
        assert_nil elems.first["url"], "expected to not find a url attribute on element:\n#{elems.first}"
      end
    end

    def test_get_new_without_party
      get :new
      assert_response :success
      assert_not_nil assigns(:address)
      assert assigns(:address).new_record?
      assert_nil assigns(:address).routable
      assert_template "_address_contact_route"
      assert_select "#new_address_contact_route_line1_edit" do |elems|
        assert_equal 1, elems.size
        assert_nil elems.first["url"], "expected to not find a url attribute on element:\n#{elems.first}"
      end
    end
  end

  class UserWithEditOwnAccountPermissionOnlyCan < Test::Unit::TestCase
    def setup
      @controller = AddressContactRoutesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
  
      @bob = login_with_permissions!(:bob, :edit_own_account)
      @address = @bob.main_address
      @address.save!
    end

    def test_create_new_address_through_party
      assert_difference AddressContactRoute, :count, 1 do
        post :create, :party_id => @bob.id, :address => {"6" => {:line1 => "xxx line 1 xxx"}}
      end

      assert_response :success
      assert_not_nil @bob.addresses(true).find_by_line1("xxx line 1 xxx")
    end

    def test_update_own_address_through_party
      put :update, :party_id => @bob.id, :id => @address.id, :address => {@address.id.to_s => {:line1 => "new line 1"}}
      assert_response :success

      @address.reload
      assert_equal "new line 1", @address.line1.downcase
    end

    def test_delete_own_address_through_party
      assert_difference AddressContactRoute, :count, -1 do
        delete :destroy, :party_id => @bob.id, :id => @address.id
      end

      assert_response :success
      assert_template "destroy"
      assert_raises(ActiveRecord::RecordNotFound) { @address.reload }
    end

    def test_delete_own_address_directly
      assert_difference AddressContactRoute, :count, -1 do
        delete :destroy, :id => @address.id
      end

      assert_response :success
      assert_template "destroy"
      assert_raises(ActiveRecord::RecordNotFound) { @address.reload }
    end

    def test_not_delete_address_from_other_party_directly
      @address = parties(:mary).main_address
      @address.save!
      assert_difference AddressContactRoute, :count, 0 do
        assert_raises(ActiveRecord::RecordNotFound) do
          delete :destroy, :id => @address.id
        end

        assert_nothing_raised { @address.reload }
      end
    end

    def test_not_delete_address_from_other_party_through_party
      @address = parties(:mary).main_address
      @address.save!
      assert_difference AddressContactRoute, :count, 0 do
        assert_raises(ActiveRecord::RecordNotFound) do
          delete :destroy, :party_id => @address.routable.id, :id => @address.id
        end

        assert_nothing_raised { @address.reload }
      end
    end
  end
end
