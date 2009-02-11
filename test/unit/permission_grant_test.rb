require File.dirname(__FILE__) + '/../test_helper'

class PermissionGrantTest < Test::Unit::TestCase
  setup do
    # ALWAYS CROSS CHECK THIS DEFAULT PERMISSIONS WITH DEFAULT PERMISSIONS IN Party#set_effective_permissions
    @default_permissions = [Permission.find_by_name("edit_own_account"), Permission.find_by_name("edit_own_contacts_only")].compact
    @account = Account.find(:first)
  end
  
  context "Attaching permission to a party" do
    setup do
      @party = @account.parties.find(:first)
      @permissions = Permission.find(:all, :limit => 8)
      
      @party.permissions << @permissions
    end
    
    should "update his/her effective permissions" do
      assert_equal((@default_permissions + @permissions).map(&:id).sort, @party.effective_permissions.map(&:id).sort)
    end
    
    context "and deleted a permission grant"do
      setup do
        @permission_grant = @party.permission_grants.find(:first).destroy
        @deleted_permission = @permission_grant.subject
      end
      
      should "update effective permissions" do
        assert_equal(((@default_permissions + @permissions).map(&:id) - [@deleted_permission.id]).sort, @party.effective_permissions.map(&:id).sort)
      end
    end
  end
  
  context "Party joining a role" do
    setup do
      @party = @account.parties.find(:first)

      @admin_role = @account.roles.build(:name => "Admin")
      assert @admin_role.save

      @admin_permissions = Permission.find(:all, :limit => 3)
      @admin_role.permissions << @admin_permissions
      
      @party.roles << @admin_role
    end
    
    should "has his/her effective permissions updated" do
      assert_equal((@default_permissions + @admin_permissions).map(&:id).sort, @party.effective_permissions.map(&:id).sort)
    end
  end
  
  context "Group has many roles and has many parties" do
    setup do
      @parties = Party.find(:all, :limit => 3)
      
      @group = @account.groups.build(:name => "Admin")
      assert @group.save
      @group.parties << @parties
      
      @staff_role = @account.roles.build(:name => "Staff")
      assert @staff_role.save
      @common_user_role = @account.roles.build(:name => "User")
      assert @common_user_role.save
      
      @group.roles << @common_user_role
      @group.roles << @staff_role
    end
    
    context "appending permissions to one of the roles" do
      setup do 
        @staff_permissions = Permission.find(:all, :limit => 2)
        @staff_role.permissions << @staff_permissions
        MethodCallbackFuture.find(:all).map(&:run)
      end
      
      should "automatically update effective permissions of the parties" do
        @parties.each do |p|
          assert_equal((@default_permissions+@staff_permissions).map(&:id).sort, p.reload.effective_permissions.map(&:id).sort)
        end
      end
    end
    
    context "assigning permissions to the group" do
      setup do
        @group_permissions = Permission.find(:all, :limit => 5)
        @group.permissions << @group_permissions
        MethodCallbackFuture.find(:all).map(&:run)
      end
      
      should "update effective permissions of parties" do
        @parties.each do |p|
          assert_equal((@default_permissions+@group_permissions).map(&:id).sort, p.reload.effective_permissions.map(&:id).sort)
        end
      end
    end
    
    context "appending a new role that has a set of permissions" do
      setup do
        @admin_role = @account.roles.build(:name => "Admin")
        assert @admin_role.save
        @admin_permissions = Permission.find(:all, :limit => 10)
        @admin_role.permissions << @admin_permissions
      end
      
      context "to the group" do
        setup do
          @group.roles << @admin_role  
          MethodCallbackFuture.find(:all).map(&:run)
        end
        
        should "automatically update effective permissions of parties" do
          @parties.each do |p|
            assert_equal((@default_permissions+@admin_permissions).map(&:id).sort, p.reload.effective_permissions.map(&:id).sort)
          end
        end
      end
    end
  end
end
