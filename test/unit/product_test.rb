require File.dirname(__FILE__) + '/../test_helper'

class ProductTest < Test::Unit::TestCase
  context "On a saved product" do
    setup do
      @account = Account.find(:first)
      @product = products(:fish)
      @fish_picture = @account.assets.build(:filename => "fish.jpg", :content_type => "image/jpg", :size => 12)
      @fish_picture.save!
      @dog_picture = @account.assets.build(:filename => "doggy.jpg", :content_type => "image/jpg" ,:size => 123)
      @dog_picture.save!
      @sunset_picture = @account.assets.build(:filename => "sunset.jpg", :content_type => "image/jpg" ,:size => 123)
      @sunset_picture.save!
      @winter_picture = @account.assets.build(:filename => "winter.jpg", :content_type => "image/jpg" ,:size => 123)
      @winter_picture.save!
    end
    
    context "calling image_ids= without saving the product" do
      setup do
        @product.image_ids = [@fish_picture.id, @dog_picture.id]        
      end
      
      should "return the new assigned array when calling Product#image_ids" do
        assert_equal [@fish_picture.id, @dog_picture.id], @product.image_ids
      end
    end
    
    context "calling image_ids=" do
      setup do
        @product.image_ids = [@fish_picture.id, @dog_picture.id]
        @product.save!
        @product.reload
      end
      
      should "append asset to the product" do
        assert_equal [@fish_picture.id, @dog_picture.id].sort, @product.views.map(&:asset_id).sort
      end
      
      context "and then calling image_ids= the second time" do
        setup do
          @product.image_ids = [@sunset_picture.id, @winter_picture.id]
          @product.save!
          @product.reload
        end
        
        should "append asset to the product properly" do
        assert_equal [@sunset_picture.id, @winter_picture.id].sort, @product.views.map(&:asset_id).sort
        end
      end
    end
    
    context "calling polygons=" do
      context "with Hash that contains points as String" do
        setup do
          @product.polygons = {
            "0" => {:description => "this is something", :points => "[ [1, 2.32] ,[2,.3],[ 4.32,-.015]]"},
            "1" => {:description => "another set of points", :points => "[ [1, 2.32] ,[5,.6],[ 4.32,-.015]]"}
          }
        end
        
        should "initialize the Polygon objects and relate the objects correctly" do
          assert_equal 2, @product.polygons.size # need to call size here because it's a new object
          assert_equal [[1,2.32],[2,0.3],[4.32,-0.015]], @product.polygons.first.points
          assert_equal [[1,2.32],[5,0.6],[4.32,-0.015]], @product.polygons.last.points
        end
        
        should "be able to save the products" do
          @product.save!
        end
      end
      
      context "with NilClass" do
        should "raise NoMethodError" do
          assert_raise NoMethodError do
            @product.polygons = nil
          end
        end
      end
      
      context "with array of Hash" do
        should "raise ActiveRecord::AssociationTypeMismatch" do
          assert_raise ActiveRecord::AssociationTypeMismatch do
            @product.polygons = [
              {:description => "this is something", :points => "[ [1, 2.32] ,[2,.3],[ 4.32,-.015]]"}, 
              {:description => "another set of points", :points => "[ [1, 2.32] ,[5,.6],[ 4.32,-.015]]"}
            ]
          end
        end
      end
      
      context "with blank array" do
        setup do
          @product.polygons = []
        end
        
        should "return blank array" do
          assert_equal [], @product.polygons
        end
      end
      
      context "with array of Polygon" do
        setup do
          @product.polygons = [Polygon.new(:description => "first one"), Polygon.new(:description => "second one")]
        end
        
        should "set the relation correctly" do
          assert_equal 2, @product.polygons.size
        end
      end
    end
  end
  
  context "Adding product to" do
    setup do
      @account = Account.find(:first)
      @product = products(:fish)
      @animals = @account.product_categories.create!(:label => "animals", :name => "Animals")
      @non_land = @account.product_categories.create!(:label => "non-land", :name => "Non-land", :parent => @animals)
    end
    
    context "a root category" do
      setup do
        @product.add_to_category_ids!([@animals.id])
      end
      
      should "add it only to the root category" do
        assert_equal 1, @product.reload.categories.count
        assert_equal @animals.id, @product.category_ids.first
      end
    end
    
    context "a child category" do
      setup do
        @product.add_to_category_ids!([@non_land.id])
      end
      
      should "add it to all the child category and its ancestors" do
        assert_equal @non_land.ancestors.size + 1, @product.categories.count
        assert_equal (@non_land.ancestors.map(&:id) + [@non_land.id]).sort, @product.categories.all(:select => "id").map(&:id).sort
      end
    end
    
    context "a child category and one if its ancestors" do
      setup do
        @product.add_to_category_ids!([@non_land.id, @animals.id])
      end
      
      should "not create duplicates in categories relationship" do
        assert_equal @non_land.ancestors.size + 1, @product.categories.count
        assert_equal (@non_land.ancestors.map(&:id) + [@non_land.id]).sort, @product.categories.all(:select => "id").map(&:id).sort
      end
    end
  end
  
  def setup
    @account = Account.find(:first)
  end

  def test_initialize_wholesale_peak_and_low_price
    product = Product.new(:account_id => @account.id, :name => "doggy")
    product.wholesale_price = Money.new(3999)
    product.save
    assert_equal Money.new(3999), product.wholesale_price
    assert_equal product.wholesale_price, product.wholesale_peak_price
    assert_equal product.wholesale_price, product.wholesale_low_price
  end

  def test_update_wholesale_peak_and_low_price
    product = products(:fish)
    product.wholesale_price = Money.new(1000)
    product.save
    assert_equal Money.new(1000), product.wholesale_peak_price
    assert_equal Money.new(500), product.wholesale_low_price
    product.wholesale_price = Money.new(250)
    product.save
    assert_equal Money.new(1000), product.wholesale_peak_price
    assert_equal Money.new(250), product.wholesale_low_price
  end

  def test_margin_should_be_zero_when_wholesale_price_is_zero
    product = products(:fish)
    product.wholesale_price = Money.new(0)
    product.save
    assert_equal 0, product.margin
  end

  def test_margin_calculated_properly
    product = products(:fish)
    product.wholesale_price = Money.new(800)
    product.save
    assert_equal 25, product.margin
  end

  def test_creator_name_updated_correctly
    product = Product.new(:account_id => @account.id, :name => "doggy")
    product.creator = parties(:admin)
    product.save
    assert_equal parties(:admin).display_name, product.creator_name
  end

  def test_editor_name_updated_correctly
    product = products(:fish)
    product.editor = parties(:bob)
    product.save
    assert_equal parties(:bob).display_name, product.editor_name
  end
  
  context "Price related attributes" do
    setup do
      @product = products(:fish)
    end
    
    should "know about currency" do
      assert_equal "CAD", @product.wholesale_price.currency
      assert_equal 500, @product.wholesale_price.cents
      @product.wholesale_price = "750 USD"
      assert_equal "USD", @product.wholesale_price.currency
      assert_equal 75000, @product.wholesale_price.cents
      @product.wholesale_price = 750.to_money
      assert_equal "CAD", @product.wholesale_price.currency
      assert_equal 750, @product.wholesale_price.cents
      @product.wholesale_price = "500"      
      assert_equal "CAD", @product.wholesale_price.currency
      assert_equal 50000, @product.wholesale_price.cents
    end
  end
end
