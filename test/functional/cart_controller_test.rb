require File.dirname(__FILE__) + '/../test_helper'
require 'cart_controller'

# Re-raise errors caught by the controller.
class CartController; def rescue_action(e) raise e end; end

class CartControllerTest < Test::Unit::TestCase
  def setup
    @controller = CartController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @account = accounts(:wpul)
    @request.env["HTTP_REFERER"] = "/"
  end

  context "A cart generated from an estimate" do
    setup do
      @estimate = create_estimate(:shipping_fee => Money.new(3000))
      @estimate.lines.create!(:quantity => 2, :retail_price => Money.new(1500), :product => Product.find(:first))
      post :from_estimate, :uuid => @estimate.uuid
      assert_nothing_raised do
        @cart = Cart.find(session[:cart_id])
      end
    end
    
    should "have the estimate copied over" do
      %w(fst_name fst_rate pst_rate pst_name shipping_fee).each do |attr|
        assert_equal @cart.send(attr), @estimate.send(attr)
      end
    end
    
    should "have the estimate lines copied over" do
      lines = @cart.lines.products
      assert_equal lines.size, 1
      %w(quantity retail_price product).each do |attr|
        assert_equal @estimate.lines.first.send(attr), lines.first.send(attr) 
      end
    end
    
    should "have a comment line referencing the Estimate" do
      lines = @cart.lines.comments
      assert_equal lines.size, 1
      assert_include @estimate.uuid, lines.first.description
    end
  end

  context "An anonymous user" do
    context "with no existing cart" do
      context "calling PUT /cart" do
        setup do
          post :update, :cart => {}
        end

        should "be redirected back" do
          assert_response :redirect
          assert_redirected_to "/"
        end

        should "remember the cart's ID in the session" do
          assert_not_nil session[:cart_id]
        end

        should "create a Cart in the database" do
          assert_nothing_raised do
            Cart.find(session[:cart_id])
          end
        end
      end

      context "calling DELETE destroy" do
        should "do nothing" do
          assert_difference Cart, :count, 0 do
            delete :destroy
          end
        end
      end      
    end

    context "with a Cart in the session" do
      setup do
        @cart = Cart.new(:account => @account)
        @cart.save(false)

        @request.session[:cart_id] = @cart.id
      end

      context "calling PUT /cart specifying name and contact parameters" do
        setup do
          @cart_count = Cart.count
          @party_count = Party.count
          @address_count = AddressContactRoute.count
          @phone_count = PhoneContactRoute.count
          @email_count = EmailContactRoute.count
          put :update, {:cart => {
              :invoice_to_attrs => {:full_name => "FirstName LastName"},
              :ship_to_attrs => {:line1 => "12345", :line2 => "Aloha Street", :state => "BC", :country => "CAN", :zip => "VVV 123"},
              :phone_attrs => {:number => "6667778888"},
              :email_attrs => {:email_address => "aloha@test.com"}},
            :return_to => "/"}
          @cart.reload
        end
        
        should "not insert new cart into the database" do
          assert_equal @cart_count, Cart.count
        end
        
        should "add a new party with proper full name" do
          assert_equal @party_count+1, Party.count
          assert_equal "FirstName LastName", @cart.invoice_to.name.to_s
        end
        
        should "add shipping address to the cart" do
          assert_equal @address_count+1, AddressContactRoute.count
          assert_equal "12345", @cart.ship_to.line1
          assert_equal "Aloha Street", @cart.ship_to.line2
          assert_equal "BC", @cart.ship_to.state
          assert_equal "CAN", @cart.ship_to.country
          assert_equal "VVV 123", @cart.ship_to.zip
        end

        should "add phone to the cart" do
          assert_equal @phone_count+1, PhoneContactRoute.count
          assert_equal "6667778888", @cart.phone.number
        end

        should "add email to the cart" do
          assert_equal @email_count+1, EmailContactRoute.count
          assert_equal "aloha@test.com", @cart.email.email_address
        end
        
        should "return to the url specified by the params[:return_to]" do
          assert_redirected_to "/"
        end
      end

      context "calling DELETE destroy" do
        setup do
          delete :destroy
        end

        should "destroy the cart" do
          assert_raise ActiveRecord::RecordNotFound do
            @cart.reload
          end
        end

        should "remove the reference to the cart from the session" do
          assert_nil session[:cart_id]
        end
      end
    end
  end

  context "A logged in user" do
    setup do
      @bob = login_with_no_permissions!(:bob)
    end

    context "with no previous cart" do
      should "be redirected to params[:return_to]" do
        put :update, :cart => {}, :return_to => "/some/url"
        assert_redirected_to "/some/url"
      end

      context "calling PUT update" do
        setup do
          put :update, :cart => {}
        end

        should "be redirected back" do
          assert_response :redirect
          assert_redirected_to "/"
        end

        should "remember the cart's ID in the session" do
          assert_not_nil session[:cart_id]
        end

        should "have created a Cart in the database" do
          assert_nothing_raised do
            Cart.find(session[:cart_id])
          end
        end

        should "have associated the cart with the logged in user" do
          assert_equal @bob, assigns(:cart).invoice_to
        end
      end
    end

    context "with an existing cart" do
      setup do
        @cart = Cart.new(:invoice_to => @bob, :account => @account)
        my_fish = products(:fish)
        my_dog = products(:dog)
        @cart.save!
        CartLine.create!(:cart => @cart, :product => my_fish, :quantity => 2)
        CartLine.create!(:cart => @cart, :product => my_dog, :quantity => 3)
      end

      context "calling PUT /cart specifying name and contact parameters" do
        setup do
          @cart_count = Cart.count
          @party_count = Party.count
          @address_count = AddressContactRoute.count
          @phone_count = PhoneContactRoute.count
          @email_count = EmailContactRoute.count
          put :update, {:cart => {
              :invoice_to_attrs => {:full_name => "FirstName LastName"},
              :ship_to_attrs => {:line1 => "12345", :line2 => "Aloha Street", :state => "BC", :country => "CAN", :zip => "VVV 123"},
              :phone_attrs => {:number => "6667778888"},
              :email_attrs => {:email_address => "aloha@test.com"}},
            :return_to => "/"}
          @cart.reload
        end
        
        should "not insert new cart into the database" do
          assert_equal @cart_count, Cart.count
        end
        
        should "not add a new party" do
          assert_equal @party_count, Party.count
        end
        
        should "not replace the party name" do
          assert_equal @bob.name.to_s, @cart.invoice_to.name.to_s
        end
        
        should "add shipping address to the cart" do
          assert_equal @address_count+1, AddressContactRoute.count
          assert_equal "12345", @cart.ship_to.line1
          assert_equal "Aloha Street", @cart.ship_to.line2
          assert_equal "BC", @cart.ship_to.state
          assert_equal "CAN", @cart.ship_to.country
          assert_equal "VVV 123", @cart.ship_to.zip
        end

        should "add phone to the cart" do
          assert_equal @phone_count+1, PhoneContactRoute.count
          assert_equal "6667778888", @cart.phone.number
        end

        should "add email to the cart" do
          assert_equal @email_count+1, EmailContactRoute.count
          assert_equal "aloha@test.com", @cart.email.email_address
        end

        should "return to the url specified by the params[:return_to]" do
          assert_redirected_to "/"
        end
      end

      context "calling DELETE destroy" do
        setup do
          delete :destroy
        end

        should "destroy the cart" do
          assert_raise ActiveRecord::RecordNotFound do
            @cart.reload
          end
        end

        should "remove the reference to the cart from the session" do
          assert_nil session[:cart_id]
        end
      end
      
      context "checking out the cart" do
        setup do
          @order_count = Order.count
          post :checkout, :next => "/next/orders/__uuid__/confirm"
        end
        
        should "destroy the cart afterwards" do
          assert_raise ActiveRecord::RecordNotFound do
            Cart.find(@cart.id)
          end
        end
        
        should "create an order from the cart" do
          assert_equal @order_count + 1, Order.count
        end
        
        should "get redirected to /next/orders/__uuid__/confirm" do
          order = assigns(:order)
          assert_redirected_to "/next/orders/"+order.uuid+"/confirm"
        end
      end
    end
  end
end
