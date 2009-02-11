require File.dirname(__FILE__) + '/../test_helper'
require 'permission_grants_controller'

# Re-raise errors caught by the controller.
class PermissionGrantsController; def rescue_action(e) raise e end; end

class PermissionGrantsControllerTest < Test::Unit::TestCase
  def setup
    @controller = PermissionGrantsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @bob = login_with_permissions!(:bob, :edit_party_security)
    @permission = Permission.create!(:name => "abc")
  end

  def test_can_associate_permission_with_party
    post :update, :party_id => @bob.id, :permission_ids => @permission.id, :format => "js"
    assert_response :success

    assert @bob.permissions(true).map(&:name).include?(@permission.name),
        @bob.permissions(true).map(&:name).inspect + " should have included #{@permission.name.inspect}"
    assert_select_rjs :replace_html, "effective_permissions"
  end

  def test_can_destroy_association_between_permission_and_party
    @bob.permissions << @permission

    delete :update, :party_id => @bob.id, :permission_ids => @permission.id, :format => "js"
    assert_response :success

    assert !@bob.permissions(true).map(&:name).include?(@permission.name),
        @bob.permissions(true).map(&:name).inspect + " should NOT have included #{@permission.name.inspect}"
    assert_select_rjs :replace_html, "effective_permissions"
  end

  def test_can_mass_associate_party_and_permissions
    @perm0 = Permission.create!(:name => "def")
    post :update, :party_id => @bob.id,
        :permission_ids => [@permission.id, @perm0.id].map(&:to_s).join(",")
    assert_response :success
    assert_select_rjs :replace_html, "effective_permissions"

    @perms = @bob.permissions(true).map(&:name)
    assert @perms.include?("abc"), "#{@perms.inspect} does not include 'abc'"
    assert @perms.include?("def"), "#{@perms.inspect} does not include 'def'"
  end

  def test_can_mass_dissociate_party_and_permissions
    @perm0 = Permission.create!(:name => "def")
    @bob.permissions << [@permission, @perm0]
    delete :update, :party_id => @bob.id,
        :permission_ids => [@permission.id, @perm0.id].map(&:to_s).join(",")
    assert_response :success
    assert_select_rjs :replace_html, "effective_permissions"

    @perms = @bob.permissions(true).map(&:name)
    assert !@perms.include?("abc"), "#{@perms.inspect} still includes 'abc'"
    assert !@perms.include?("def"), "#{@perms.inspect} still includes 'def'"
  end
end
