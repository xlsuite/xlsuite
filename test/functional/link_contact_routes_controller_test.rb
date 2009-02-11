require File.dirname(__FILE__) + '/../test_helper'
require 'link_contact_routes_controller'

# Re-raise errors caught by the controller.
class LinkContactRoutesController; def rescue_action(e) raise e end; end

module LinkContactRoutesControllerTest
  class UserWithEditPartyPermissionCan < Test::Unit::TestCase
    def setup
      @controller = LinkContactRoutesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new

      @bob = login_with_permissions!(:bob, :edit_party)
      @link = @bob.main_link
      @link.url = "my.host.com"
      @link.save!
    end

    def test_create
      assert_difference LinkContactRoute, :count, 1 do
        post :create, :party_id => @bob.id, :link => {"8" => {:url => "www.xlsuite.org"}}
        assert_response :success
        assert_template "create"
        assert_not_nil @bob.links(true).find_by_url("www.xlsuite.org")
      end
    end

    def test_show
      get :show, :party_id => @bob.id, :id => @link.id
      assert_response :success
      assert_template "_link_contact_route"
      assert_select "\#link_contact_route_#{@link.id}_url_edit[url=?]",
          party_link_path(@bob, @link)
    end

    def test_update
      assert_difference LinkContactRoute, :count, 0 do
        xhr :put, :update, :party_id => @bob.id, :id => @link.id, :link => {@link.id.to_s => {:url => "some.server.net"}}
        assert_response :success
        assert_equal "some.server.net", @bob.main_link(true).url
      end
    end

    def test_destroy
      assert_difference LinkContactRoute, :count, -1 do
        xhr :delete, :destroy, :party_id => @bob.id, :id => @link.id
        assert_response :success
      end
    end

    def test_get_new_against_existing_party
      get :new, :party_id => @bob.id
      assert_not_nil assigns(:link)
      assert assigns(:link).new_record?
      assert_equal @bob, assigns(:link).routable
      assert_template "_link_contact_route"
      assert_select "#new_link_contact_route_url_edit" do |elems|
        assert_equal 1, elems.size
        assert_nil elems.first["url"], "expected to not find a url attribute on element:\n#{elems.first}"
      end
    end

    def test_get_new_without_party
      get :new
      assert_response :success
      assert_not_nil assigns(:link)
      assert assigns(:link).new_record?
      assert_nil assigns(:link).routable
      assert_template "_link_contact_route"
      assert_select "#new_link_contact_route_url_edit" do |elems|
        assert_equal 1, elems.size
        assert_nil elems.first["url"], "expected to not find a url attribute on element:\n#{elems.first}"
      end
    end

    def test_delete_by_clearing_out_the_url_field
      assert_difference LinkContactRoute, :count, -1 do
        xhr :put, :update, :party_id => @bob.id, :id => @link.id, :link => {@link.id.to_s => {:url => ""}}
      end

      assert_response :success
      assert_template "destroy"
      assert_raises(ActiveRecord::RecordNotFound) { @link.reload }
    end

    def test_change_name_field_only
      assert_difference LinkContactRoute, :count, 0 do
        xhr :put, :update, :party_id => @bob.id, :id => @link.id, :link => {@link.id.to_s => {:name => "sentinel"}}
      end

      assert_response :success
      assert_template "update"
      assert_equal "sentinel", @link.reload.name.downcase
    end
  end

  class UserWithEditOwnAccountPermissionOnlyCan < Test::Unit::TestCase
    def setup
      @controller = LinkContactRoutesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
  
      @bob = login_with_permissions!(:bob, :edit_own_account)
      @link = @bob.main_link
      @link.url = "his.site.com"
      @link.save!
    end

    def test_create_new_link_through_party
      assert_difference LinkContactRoute, :count, 1 do
        post :create, :party_id => @bob.id, :link => {"9" => {:url => "my.site.com"}}
      end

      assert_response :success
      assert_not_nil @bob.links(true).find_by_url("my.site.com")
    end

    def test_update_own_link_through_party
      put :update, :party_id => @bob.id, :id => @link.id, :link => {@link.id.to_s => {:url => "their.site.com"}}
      assert_response :success

      @link.reload
      assert_equal "their.site.com", @link.url.downcase
    end

    def test_delete_own_link_through_party
      assert_difference LinkContactRoute, :count, -1 do
        delete :destroy, :party_id => @bob.id, :id => @link.id
      end

      assert_response :success
      assert_template "destroy"
      assert_raises(ActiveRecord::RecordNotFound) { @link.reload }
    end

    def test_delete_own_link_directly
      assert_difference LinkContactRoute, :count, -1 do
        delete :destroy, :id => @link.id
      end

      assert_response :success
      assert_template "destroy"
      assert_raises(ActiveRecord::RecordNotFound) { @link.reload }
    end

    def test_not_delete_link_from_other_party_directly
      @link = parties(:mary).main_link
      @link.url = "their.site.com"
      @link.save!
      assert_difference LinkContactRoute, :count, 0 do
        assert_raises(ActiveRecord::RecordNotFound) do
          delete :destroy, :id => @link.id
        end

        assert_nothing_raised { @link.reload }
      end
    end

    def test_not_delete_link_from_other_party_through_party
      @link = parties(:mary).main_link
      @link.url = "their.site.com"
      @link.save!
      assert_difference LinkContactRoute, :count, 0 do
        assert_raises(ActiveRecord::RecordNotFound) do
          delete :destroy, :party_id => @link.routable.id, :id => @link.id
        end

        assert_nothing_raised { @link.reload }
      end
    end
  end
end
