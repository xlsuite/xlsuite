require File.dirname(__FILE__) + '/../test_helper'
require 'memberships_controller'

# Re-raise errors caught by the controller.
class MembershipsController; def rescue_action(e) raise e end; end

class MembershipsControllerTest < Test::Unit::TestCase
  def setup
    @controller = MembershipsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @bob = login_with_permissions!(:bob, :edit_party_security)
    @account = @bob.account
    @old_group = @bob.groups(true).dup
    @group = @account.groups.create!(:name => "abc")
      
  end

  def test_can_associate_group_with_party
    post :update, :party_id => @bob.id, :group_ids => @group.id, :format => "js"
    assert_response :success

    assert_equal [@group, @old_group].flatten.map(&:name), @bob.groups(true).map(&:name)
    assert_select_rjs :replace_html, "effective_permissions"
  end

  def test_can_destroy_association_between_group_and_party
    @bob.groups << @group

    delete :update, :party_id => @bob.id, :group_ids => @group.id, :format => "js"
    assert_response :success

    assert_equal [@old_group].flatten.map(&:name), @bob.groups(true).map(&:name)
    assert_select_rjs :replace_html, "effective_permissions"
  end

  def test_can_mass_associate_groups_with_party 
    @group0 = @account.groups.create!(:name => "def")
    post :update, :party_id => @bob.id,
        :group_ids => [@group.id, @group0.id].map(&:to_s).join(","), :format => "js"
    assert_response :success
    assert_select_rjs :replace_html, "effective_permissions"

    assert_equal [@group, @group0, @old_group].flatten.map(&:name).sort, @bob.groups(true).map(&:name).sort
  end

  def test_can_mass_dissociate_groups_from_party   
    @group0 = @account.groups.create!(:name => "def")
    @bob.groups << [@group, @group0]
    assert_difference(lambda { Group.connection.select_values("SELECT COUNT(*) FROM memberships").first.to_i }, :call, -2) do
      delete :update, :party_id => @bob.id,
          :group_ids => [@group.id, @group0.id].map(&:to_s).join(","), :format => "js"
      assert_response :success
      assert_select_rjs :replace_html, "effective_permissions"
    end

    assert_equal [ @old_group].flatten.map(&:name), @bob.groups(true).map(&:name)
  end
end
