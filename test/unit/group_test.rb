require File.dirname(__FILE__) + '/../test_helper'

class GroupTest < Test::Unit::TestCase
  context "Assigning parties to group" do
    setup do
      @account = Account.find(:first)
      
      @group = @account.groups.build(:name => "abc")    
      @group.save!

      @bob = parties(:bob)
      @mary = parties(:mary)
      @bob_old_groups = @bob.groups(true)

      @group.parties << @bob
      @group.parties << @mary      
    end
    
    should "setup the relations correctly" do    
      assert_equal [@group, @bob_old_groups].flatten.compact.map(&:id).sort, @bob.groups(true).map(&:id).sort
      assert_not_nil @group.parties(true).map(&:id).index(@bob.id)
      assert_not_nil @group.parties(true).map(&:id).index(@mary.id)      
    end
    
    context "using Group#party_ids=" do
      setup do
        @party_ids = @account.parties.find(:all).map(&:id) - [@bob.id, @mary.id]
        
        assert_nothing_raised do
          @group.party_ids = @party_ids      
        end      
      end
      
      should "create the relations correctly" do
        assert_equal @party_ids.size, @group.parties.count    
      end
      
      should "remove the old relations" do
        assert_nil @group.parties.map(&:id).index(@bob.id)
        assert_nil @group.parties.map(&:id).index(@mary.id)         
      end    
    end
  end
  
  context "Permissions appended to a parent group" do
    setup do
      @account = Account.find(:first)
      @parent = @account.groups.build(:name => "parent")
      assert @parent.save
      @permissions = Permission.find(:all, :limit => 3)
      @parent.permissions << @permissions  
      assert_equal @permissions.map(&:id).sort, @parent.total_granted_permissions.map(&:id).sort
    end
    
    should "propagate to its children and grandchildren" do
      @child1 = @account.groups.build(:name => "child1")
      @child1.parent = @parent
      assert @child1.save
      assert_equal 0, @child1.permissions.count   
      assert_equal 3, @child1.total_granted_permissions.size
      
      @grandchild1 = @account.groups.build(:name => "grandchild1")
      @grandchild1.parent = @child1      
      assert @grandchild1.save
      assert_equal 0, @grandchild1.permissions.count   
      assert_equal 3, @grandchild1.total_granted_permissions.size
    end
  end
  
  context "Permissions appended to a child group" do
    setup do 
      @account = Account.find(:first)
      @parent = @account.groups.build(:name => "parent")
      assert @parent.save

      @child1 = @account.groups.build(:name => "child1")
      @child1.parent = @parent
      assert @child1.save

      @permissions = Permission.find(:all, :limit => 3)
      @child1.permissions << @permissions  
      assert_equal @permissions.map(&:id).sort, @child1.total_granted_permissions.map(&:id).sort
      
      @parent.reload
    end
    
    should "not propagate to parent role" do
      assert_equal 0, @parent.permissions.count   
      assert_equal 0, @parent.total_granted_permissions.size
    end
  end
end
