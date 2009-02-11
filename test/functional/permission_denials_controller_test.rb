require File.dirname(__FILE__) + '/../test_helper'
require 'permission_denials_controller'

# Re-raise errors caught by the controller.
class DeniedPermissionsController; def rescue_action(e) raise e end; end

module DeniedPermissionsControllerRoutingTest
  class UserWithEditPartySecurityTest < Test::Unit::TestCase
    def setup
      @controller = DeniedPermissionsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
  
      @bob = login_with_permissions!(:bob, :edit_party_security, :edit_party)
      @account = @bob.account
      @party = @account.parties.create!
      @perm = Permission.find(:first)
    end

    def test_can_create_permission_denial
      post :update, :party_id => @party.id, :permission_ids => @perm.id
      assert_response :success
      assert_template "roles/_reset_effective_permissions"
      assert @party.permission_denials(true).include?(@perm),
          "#{@party.permission_denials(true).map(&:name).inspect} does not contain #{@perm.name.inspect}"
    end

    def test_can_destroy_permission_denial
      @party.permission_denials << @perm
      delete :update, :party_id => @party.id, :permission_ids => @perm.id
      assert_response :success
      assert_template "roles/_reset_effective_permissions"
      assert !@party.permission_denials(true).include?(@perm),
          "#{@party.permission_denials(true).map(&:name).inspect} still contains #{@perm.name.inspect}"
    end

    def test_can_mass_create_permission_denials
      @perm0 = Permission.find(:first, :offset => 1)
      post :update, :party_id => @party.id, :permission_ids => [@perm.id, @perm0.id].map(&:to_s).join(",")
      assert_response :success
      assert_template "roles/_reset_effective_permissions"

      assert @party.permission_denials(true).include?(@perm),
          "#{@party.permission_denials(true).map(&:name).inspect} does not contain #{@perm.name.inspect}"
      assert @party.permission_denials(true).include?(@perm0),
          "#{@party.permission_denials(true).map(&:name).inspect} does not contain #{@perm0.name.inspect}"
    end

    def test_can_mass_destroy_permission_denials
      @perm0 = Permission.find(:first, :offset => 1)
      @party.permission_denials << [@perm, @perm0]
      delete :update, :party_id => @party.id, :permission_ids => [@perm.id, @perm0.id].map(&:to_s).join(",")
      assert_response :success
      assert_template "roles/_reset_effective_permissions"

      assert !@party.permission_denials(true).include?(@perm),
          "#{@party.permission_denials(true).map(&:name).inspect} still contains #{@perm.name.inspect}"
      assert !@party.permission_denials(true).include?(@perm0),
          "#{@party.permission_denials(true).map(&:name).inspect} still contains #{@perm0.name.inspect}"
    end
  end

  class UserWithoutEditPartySecurityTest < Test::Unit::TestCase
    def setup
      @controller = DeniedPermissionsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
  
      @bob = login_with_no_permissions!(:bob)
      @account = @bob.account
      @party = @account.parties.create!
      @perm = Permission.find(:first)
    end

    def test_cannot_create
      post :update, :party_id => @party.id, :permission_id => @perm.id
      assert_response :redirect
      assert_redirected_to new_session_path
    end

    def test_cannot_destroy
      delete :update, :party_id => @party.id, :permission_id => @perm.id
      assert_response :redirect
      assert_redirected_to new_session_path
    end
  end
end
