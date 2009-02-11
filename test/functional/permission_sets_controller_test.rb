require File.dirname(__FILE__) + '/../test_helper'
require 'permission_sets_controller'

# Re-raise errors caught by the controller.
class PermissionSetsController; def rescue_action(e) raise e end; end

module PermissionSetsControllerTest
  class AnonymousAccessToTest < Test::Unit::TestCase
    def setup
      @controller = PermissionSetsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
  
      @account = Account.find(:first)
      @permission_set = @account.permission_sets.create!(:name => "abc")
    end

    def test_index_rejected
      get :index
      assert_response :redirect
      assert_redirected_to new_session_path
    end

    def test_show_rejected
      get :show, :id => @permission_set.id
      assert_response :redirect
      assert_redirected_to new_session_path
    end

    def test_edit_rejected
      get :edit, :id => @permission_set.id
      assert_response :redirect
      assert_redirected_to new_session_path
    end

    def test_update_rejected
      put :update, :id => @permission_set.id, :permission_set => {}
      assert_response :redirect
      assert_redirected_to new_session_path
    end

    def test_create_rejected
      post :create, :permission_set => {:name => "aslak"}
      assert_response :redirect
      assert_redirected_to new_session_path
   end

    def test_destroy_rejected
      delete :destroy, :id => @permission_set.id
      assert_response :redirect
      assert_redirected_to new_session_path
    end

    def test_new_rejected
      get :index
      assert_response :redirect
      assert_redirected_to new_session_path
    end
  end

  class AuthenticatedSansEditPermissionSetsPermissionAccessToTest < Test::Unit::TestCase
    def setup
      @controller = PermissionSetsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
  
      @bob = login_with_no_permissions!(:bob)
      @account = @bob.account
      @permission_set = @account.permission_sets.create!(:name => "abc")
    end

    def test_index_rejected
      get :index
      assert_template "shared/rescues/unauthorized"
    end

    def test_show_rejected
      get :show, :id => @permission_set.id
      assert_template "shared/rescues/unauthorized"
    end

    def test_edit_rejected
      get :edit, :id => @permission_set.id
      assert_template "shared/rescues/unauthorized"
    end

    def test_update_rejected
      put :update, :id => @permission_set.id, :permission_set => {}
      assert_template "shared/rescues/unauthorized"
    end

    def test_create_rejected
      post :create, :permission_set => {:name => "aslak"}
      assert_template "shared/rescues/unauthorized"
   end

    def test_destroy_rejected
      delete :destroy, :id => @permission_set.id
      assert_template "shared/rescues/unauthorized"
    end

    def test_new_rejected
      get :index
      assert_template "shared/rescues/unauthorized"
    end
  end

  class AuthenticatedWithPermissionCanTest < Test::Unit::TestCase
    def setup
      @controller = PermissionSetsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
  
      @bob = login_with_permissions!(:bob, :edit_permission_sets)
      @account = @bob.account
      @permission_set = @account.permission_sets.create!(:name => "abc")
      @group = @account.groups.create!(:name => "a group")
    end

    def test_get_index
      get :index
      assert_response :success
      assert_template "index"
      assert_not_nil assigns(:permission_sets)
      assert_not_nil assigns(:pager)
      assert_not_nil assigns(:page)

      deny assigns(:permission_sets).include?(@group),
          "PermissionSets should not show groups."
    end

    def test_get_show
      get :show, :id => @permission_set.id
      assert_response :success
      assert_template "show"
      assert_not_nil assigns(:permission_set)
    end

    def test_get_new
      get :new
      assert_response :success
      assert_template "new"
      assert_not_nil assigns(:permission_set)
    end

    def test_get_edit
      get :edit, :id => @permission_set.id
      assert_response :success
      assert_template "edit"
      assert_not_nil assigns(:permission_set)
    end

    def test_get_edit_xhr
      xhr :get, :edit, :id => @permission_set.id
      assert_response :success
      assert_template "_form"
      assert_not_nil assigns(:permission_set)
    end

    def test_create
      @mary = parties(:mary)
      @perm0 = Permission.create!(:name => "perm0")
      @perm1 = Permission.create!(:name => "perm1")

      assert_difference PermissionSet, :count, 1 do
        post :create, :permission_set => {:name => "Admins",
            :permission_ids => [@perm0, @perm1].map(&:id).map(&:to_s),
            :children_ids => [].map(&:id).map(&:to_s)}
        assert_response :redirect, @response.body
        assert_redirected_to permission_sets_path
      end

      assert_not_nil @permission_set = assigns(:permission_set)
      @permission_set.reload
      assert_equal "Admins", @permission_set.name
      assert_equal @bob, @permission_set.created_by
      assert_equal @bob, @permission_set.updated_by
      assert_equal [@perm0, @perm1], @permission_set.permissions, "Permissions not correctly assigned"
      assert_equal [], @permission_set.children, "PermissionSet children not correctly assigned"
    end

    def test_update
      assert_nil @permission_set.updated_by

      put :update, :id => @permission_set.id, :permission_set => {:name => "Karanda"}
      assert_response :redirect
      assert_redirected_to permission_sets_path

      assert_equal "Karanda", @permission_set.reload.name
      assert_equal @bob, @permission_set.updated_by
    end

    def test_update_with_xhr
      xhr :put, :update, :id => @permission_set.id, :permission_set => {:name => "Karanda"}

      assert_response :success
      assert_template "update.rjs"
    end

    def test_destroy
      assert_difference PermissionSet, :count, -1 do
        delete :destroy, :id => @permission_set.id
      end

      assert_response :redirect
      assert_redirected_to permission_sets_path
    end
  end
end
