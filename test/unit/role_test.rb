require File.dirname(__FILE__) + '/../test_helper'

class RoleTest < Test::Unit::TestCase
  setup do
    @account = accounts(:wpul)
  end

  context "A new role object with name 'def'" do
    setup do
      @ps = @account.roles.build(:name => "def")
    end
    
    should "not be saved even if permission_ids is specified before create" do
      @permids = Permission.find(:all, :limit => 2).map(&:id)
      @ps.permission_ids = @permids
      assert @ps.new_record?, "Should not save because we assigned permission ids"
      @ps.save!
      assert_equal @permids.sort, @ps.reload.permission_ids.sort
    end
    
    should "not be saved even when children_ids is specified before create" do
      @role = @account.roles.create!(:name => "abc")
      @ps.children_ids = [@role.id]
      assert @ps.new_record?, "Should not save because we assigned children ids"
      @ps.save!
      assert_equal [@role.id], @ps.reload.children_ids
    end
  end

  context "Performing permission_ids= assignment on an existing role with name 'abc'" do
    setup do
      @role = @account.roles.create!(:name => "abc")
      @permissions = Permission.find(:all).map(&:id).map(&:to_s)
      assert_nothing_raised do
        @role.permission_ids = @permissions
      end

      @role.save!
    end
    
    should "assign the permissions correctly" do 
      assert_equal @permissions.size, @role.permissions(true).size
    end
    
    should "remove old permissions" do
      p = Permission.find_by_name("edit_candidate")
      @role.permission_ids = [p.id]
      @role.save!

      assert_equal %w(edit_candidate), @role.permissions(true).map(&:name)
    end
  end

  context "Calling #children_ids on an existing role named 'abc'" do
    setup do
      @role = @account.roles.create!(:name => "abc")
      @role0 = @account.roles.create!(:name => "role0")
      @role1 = @account.roles.create!(:name => "role1")
      @role.children_ids = [@role0.id, @role1.id]
      @role.save!
      @role.reload
    end
    
    should "assign the child roles correctly" do
      assert_equal 2, @role.children.size
      assert_equal [@role0, @role1].map(&:name).sort,
      @role.children.map(&:name).sort
      assert_equal @role, @role0.reload.parent
      assert_equal @role, @role1.reload.parent
    end
    
    should "remove old children" do
      @role.children_ids = [@role1.id]
      @role.save!
      @role.reload
      assert_equal 1, @role.children.size
      assert_equal [@role1].map(&:name).sort,
      @role.children.map(&:name).sort
    end
  end

  context "An existing role with name 'abc'" do
    setup do
      @role = @account.roles.create!(:name => "abc")
    end
    
    should "be able to have permissions appended without raising any exception" do
      assert_nothing_raised do
        @role.append_permissions(:edit_link)
      end
    end

    should "be able to have children roles" do
      @child = @role.children.create!(:name => "def")
      assert_equal @role, @child.reload.parent
      assert_equal [@child], @role.children(true)
    end

    should "has its children permissions" do
      @role0 = @account.roles.create!(:name => "role0")
      @role0.permissions << Permission.find_or_create_by_name("aria")
      @role.children << @role0

      assert @role.reload.effective_permissions.map(&:name).include?("aria"),
      @role.reload.effective_permissions.map(&:name).inspect + " should have included 'aria'"
    end

    should "has its grandchildren permissions" do
      @role0 = @account.roles.create!(:name => "role0")
      @role1 = @account.roles.create!(:name => "role1")

      @role1.permissions << Permission.find_or_create_by_name("aria")
      @role1.save!

      @role0.children << @role1
      @role0.save!

      @role.children << @role0
      @role.save!

      assert_include "aria", @role.effective_permissions.map(&:name)
    end
  end
  
  context "A child role" do
    setup do
      @role0 = @account.roles.create!(:name => "role0")
      @role1 = @account.roles.create!(:name => "role1")
      @role0.children_ids = [@role1.id.to_s]
      assert @role0.save
      assert_equal [@role1], @role0.reload.children
    end
  
    should "not be able to assign its parent as one of his children" do
      @role1.reload.children_ids = [@role0.id.to_s]
      assert !@role1.save
      assert_equal [], @role1.reload.children
    end
  end

  context "A role with children" do
    setup do
      @root = @account.roles.create!(:name => "root")
      @child0 = @root.children.create!(:name => "root/child0")
      @child1 = @root.children.create!(:name => "root/child1")
    end

    def test_can_return_roots_only
      assert_equal [@root], @account.roles.find_all_roots
    end
  end

  context "A role" do
    setup do
      # TODO: why do I have to keep doing this?
      @role = @account.roles.find_by_name("abc")
      @role.destroy if @role    
    end

    def test_have_permissions
      assert_nothing_raised { Role.new.permissions }
    end

    def test_requires_name
      @role = Role.new
      assert !@role.valid?
      assert /can't be blank/i, @role.errors.on(:name) #' for TextMate/Vim
    end

    def test_remembers_creator
      @role = @account.roles.build(:name => "abc", :created_by => (party = @account.parties.create!))
      @role.save!

      assert_equal party, @role.reload.created_by
    end

    def test_remembers_updator
      @role = @account.roles.build(:name => "abc", :updated_by => (party = @account.parties.create!))
      @role.save!

      assert_equal party, @role.reload.updated_by
    end
  end

  context "Another role" do
    setup do
      # ALWAYS CROSS CHECK THIS DEFAULT PERMISSIONS WITH DEFAULT PERMISSIONS IN Party#set_effective_permissions
      @default_permissions = [Permission.find_by_name("edit_own_account"), Permission.find_by_name("edit_own_contacts_only")].compact
    end

    context "Permissions appended to a parent role" do
      setup do
        @parent = @account.roles.build(:name => "parent")
        @parent.save!

        @permissions = Permission.find(:all, :limit => 3)
        @parent.permissions << @permissions  
        assert_equal @permissions.map(&:id).sort, @parent.total_granted_permissions.map(&:id).sort
      end

      should "not propagate to its children and grandchildren" do
        @child1 = @account.roles.build(:name => "child1")
        @child1.parent = @parent
        assert @child1.save
        assert_equal 0, @child1.total_granted_permissions.size

        @grandchild1 = @account.roles.build(:name => "grandchild1")
        @grandchild1.parent = @child1      
        assert @grandchild1.save
        assert_equal 0, @grandchild1.total_granted_permissions.size
      end
    end
  end

  context "A hierarchy of roles (admins => accountants => helpers)" do
    setup do
      @admin_role = @account.roles.create!(:name => "admins")
      @accountants_role = @account.roles.create!(:name => "accountants", :parent => @admin_role)
      @helpers_role = @account.roles.create!(:name => "helpers", :parent => @accountants_role)

      @admin_role.parties << parties(:peter)
      @admin_role.permissions << Permission.find_or_create_by_name("edit_party_security")

      @accountants_role.parties << parties(:mary)
      @accountants_role.permissions << Permission.find_or_create_by_name("edit_invoices")

      @helpers_role.permissions << Permission.find_or_create_by_name("view_invoices")
      @helpers_role.parties << parties(:john)

      [@admin_role, @accountants_role, @helpers_role].each(&:reload)
    end

    should "make helpers the sole child of accountants" do
      assert_equal [@helpers_role].map(&:to_s), @accountants_role.children.map(&:to_s)
    end

    should "make accountants the parent of helpers" do
      assert_equal @accountants_role.to_s, @helpers_role.parent.to_s
    end

    should "make the direct parties part of the role (John has role Helper)" do
      assert_include parties(:john).to_s, @helpers_role.total_parties.map(&:to_s)
    end

    should "make the direct ancestor party's part of a child role (Mary should be part of Helpers)" do
      assert_include parties(:mary).to_s, @helpers_role.total_parties.map(&:to_s)
    end

    should "make the full ancestor party's part of a child role (Peter should be part of Helpers)" do
      assert_include parties(:peter).to_s, @helpers_role.total_parties.map(&:to_s)
    end

    context "to which we add a permission to the middle role (accountants)" do
      setup do
        @count = MethodCallbackFuture.count
        @accountants_role.permissions << Permission.find_or_create_by_name("edit_parties")
        @future = MethodCallbackFuture.find(:first, :order => "id DESC")
      end

      should "instantiate a MethodCallbackFuture" do
        assert_equal @count + 1, MethodCallbackFuture.count
      end

      should "select all parties that are part of the role in the MethodCallbackFuture" do
        assert_equal [parties(:mary), parties(:peter)].map(&:name).map(&:to_s).sort,
            @future.models.map(&:name).map(&:to_s).sort
      end

      should "call \#generate_effective_permissions in the MethodCallbackFuture" do
        assert_equal "generate_effective_permissions", @future.method.to_s
      end
    end

    context "to which we add a permission to the bottom-most role (helpers)" do
      setup do
        @count = MethodCallbackFuture.count
        @helpers_role.permissions << Permission.find_or_create_by_name("view_parties")
        @future = MethodCallbackFuture.find(:first, :order => "id DESC")
      end

      should "instantiate a MethodCallbackFuture" do
        assert_equal @count + 1, MethodCallbackFuture.count
      end

      should "select all parties that are part of the role in the MethodCallbackFuture" do
        assert_equal [parties(:john), parties(:mary), parties(:peter)].map(&:name).map(&:to_s).sort,
            @future.models.map(&:name).map(&:to_s).sort
      end

      should "call \#generate_effective_permissions in the MethodCallbackFuture" do
        assert_equal "generate_effective_permissions", @future.method.to_s
      end
    end
  end
end
