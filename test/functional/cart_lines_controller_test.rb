require File.dirname(__FILE__) + '/../test_helper'
require 'cart_lines_controller'

# Re-raise errors caught by the controller.
class CartLinesController; def rescue_action(e) raise e end; end

class CartLinesControllerTest < Test::Unit::TestCase
  def setup
    @controller = CartLinesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @account = Account.find(1)
    @my_fish = products(:fish)
    @my_dog = products(:dog)
    
    @request.env['HTTP_REFERER'] = "/"
  end
  
  context "Passing retail_price params" do
    setup do
      @cart = @account.carts.build
      @cart.save!
      @cart_line = CartLine.new(:cart => @cart, :product => @my_fish, :quantity => 2)
      @cart_line.save!
      @request.session[:cart_id] = @cart.id
    end

    should "not change the unit price of the product cart line" do
      assert_difference CartLine, :count, 0 do
        put :update, {:id => @cart_line.id, :cart_line => {:quantity => 5, :retail_price => "123.00"}}
        @cart_line.reload
        assert_equal 5, @cart_line.quantity
        assert_equal 1000, @cart_line.retail_price_cents
      end      
    end
  end
  
  context "Anonymous user" do
    setup do
      @cart = @account.carts.build
      @cart.save!
      @cart_line = CartLine.new(:cart => @cart, :product => @my_fish, :quantity => 2)
      @cart_line.save!
      @request.session[:cart_id] = @cart.id
    end

    should "be able to add an item to his/her cart" do
      assert_difference CartLine, :count, 1 do
        post :create, {:cart_line => {:product_id => @my_dog.id, :quantity => 1}}
      end
    end
        
    should "be able to update a line item on his/her cart" do
      assert_difference CartLine, :count, 0 do
        put :update, {:id => @cart_line.id, :cart_line => {:quantity => 5}}
        @cart_line.reload
        assert_equal 5, @cart_line.quantity
        assert_equal 1000, @cart_line.retail_price_cents
      end
    end

    should "be able to delete an item from his/her cart" do
      assert_difference CartLine, :count, -1 do
        delete :destroy, {:id => @cart_line.id}
      end
    end
    
    should "be able to delete multiple items from his/her cart" do
      second_cart_line = CartLine.new(:cart => @cart, :product => @my_dog, :quantity => 2)
      second_cart_line.save!
      assert_difference CartLine, :count, -2 do
        post :destroy_collection, {:ids => [@cart_line.id, second_cart_line.id].join(",")}
      end
    end
  end
  
  context "Existing cart line" do
    setup do
      @cart = @account.carts.build
      @cart.save!
      @cart_line = CartLine.new(:cart => @cart, :product => @my_fish, :quantity => 2)
      @cart_line.save!
      @request.session[:cart_id] = @cart.id
    end
    
    should "get its quantity and retail_price attributes updated if users add the product to their shopping cart" do
      assert_difference CartLine, :count, 0 do
        post :create, {:cart_line => {:product_id => @my_fish.id, :quantity => 6}}
        @cart_line.reload
        assert_equal 8, @cart_line.quantity
        assert_equal 1000, @cart_line.retail_price.cents
      end
    end
    
    should "be removed if the quantity is set to 0" do
      assert_difference CartLine, :count, -1 do
        put :update, {:id => @cart_line.id, :cart_line => {:quantity => 0}}
      end
    end
  end
end
