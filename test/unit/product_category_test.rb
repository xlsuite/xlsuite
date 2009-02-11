require File.dirname(__FILE__) + '/../test_helper'

class ProductCategoryTest < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
  end
  
  def test_relationship_with_accounts
    pc = @account.product_categories.create!(:name => 'Action Lighting')
    assert_equal @account, pc.account
  end
  
  def test_add_avatar_to_category
    file = uploaded_file('1.jpg')
    pc = @account.product_categories.create!(:avatar => file, :name => 'Action Lighting')
    pc.reload

    assert_not_nil pc.avatar
  end

  def test_avatar_receives_category_name_as_filename
    file = uploaded_file('1.jpg')
    pc = @account.product_categories.create!(:avatar => file, :name => 'Action Lighting')
    pc.reload

    assert_equal pc.name.gsub(" ", "_"), pc.avatar.filename
  end
  
  context "Destroying a product category" do
    setup do
      @account = Account.find(1)
      @root = product_categories(:root)
      @pet = product_categories(:pet)
      @doggy = products(:dog)
      @fish = products(:fish)
      @pet.products << @doggy
      @pet.products << @fish
      @pet.reload
      assert_equal 2, @pet.products.count
    end
    
    should "destroy associated children" do
      assert_difference ProductCategory, :count, -2 do
        @root.destroy
        assert_raise ActiveRecord::RecordNotFound do
          @pet.reload
        end
      end
    end
    
    should "remove the proper has_and_belongs_to_many relationship" do
      @root.destroy
      assert_equal 0, @doggy.categories.count
      assert_equal 0, @fish.categories.count
    end
  end
end
