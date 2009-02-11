require File.dirname(__FILE__) + '/../test_helper'
require 'groups_controller'

# Re-raise errors caught by the controller.
class GroupsController; def rescue_action(e) raise e end; end

class GroupsControllerTest < Test::Unit::TestCase
  def setup
    @controller = GroupsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @account = Account.find(:first)
    @group = @account.groups.first
  end

  context "An anonymous visitor" do
    should_be_restful do |resource|
      resource.formats = %w(html)

      resource.create.params = {:name => "My Group"}
      resource.update.params = {:name => "My Group"}

      resource.denied.actions = :all
      resource.denied.flash = /Unauthorized access/i
      resource.denied.redirect = "new_session_path"
    end
  end

  context "An authenticated user without the :edit_groups permission" do
    setup do
      @bob = login_with_no_permissions!(:bob)
    end

    should_be_restful do |resource|
      resource.formats = %w(html)

      resource.create.params = {:name => "My Group"}
      resource.update.params = {:name => "My Group"}

      resource.denied.actions = :all
      resource.denied.flash = nil
      resource.denied.redirect = "new_session_path"
    end
  end

  context "An authenticated user with :edit_groups permission" do
    setup do
      @bob = login_with_permissions!(:bob, :edit_groups)
    end

    should_be_restful do |resource|
      resource.formats = %w(html)

      resource.create.params = {:name => "My Group"}
      resource.update.params = {:name => "My Group"}
      resource.create.redirect = "groups_url"
      resource.update.redirect = "groups_url"
      
      resource.create.flash = /saved/
      resource.destroy.flash = /deleted/
    end

    context "on GET to :index with {}" do
      setup do
        get :index
      end

      should_assign_to :pager
      should_assign_to :page
    end

    context "visiting \#edit using XHR" do
      setup do
        xhr :get, :edit, :id => @group.id
      end

      should_render_template "_form"
    end

    context "calling \#update using XHR" do
      setup do
        xhr :put, :update, :id => @group.id, :group => {:name => "Karanda"}
      end

      should_respond_with :success
      should_render_template "update.rjs"
    end

    context "calling \#create with permissions and parties" do
      setup do
        @mary = parties(:mary)
        @perm0 = Permission.create!(:name => "perm0")
        @perm1 = Permission.create!(:name => "perm1")

        post :create, :group => {:name => "Entry-Level Members",
            :permission_ids => [@perm0, @perm1].map(&:id).map(&:to_s),
            :party_ids => [@bob, @mary].map(&:id).map(&:to_s),
            :children_ids => [].map(&:id).map(&:to_s)}

        @group = assigns(:group).reload
      end

      should "assign the correct permissions to the group" do
        assert_equal [@perm0, @perm1].map(&:name).sort, @group.permissions.map(&:name).sort,
            "Permissions incorrectly assigned"
      end

      should "assign the selected parties to the group" do
        assert_equal [@bob, @mary].map(&:display_name).sort, @group.parties.map(&:display_name).sort,
            "Parties incorrectly assigned"
      end 

      should "not assign any children to the group" do
        assert @group.children.empty?, "Children were assigned when none expected: #{@group.children}"
      end    
    end
  end
end
