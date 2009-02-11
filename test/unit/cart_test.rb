require File.dirname(__FILE__) + '/../test_helper'

class CartTest < Test::Unit::TestCase
  context "Initializing a cart" do
    setup do 
      @account = Account.find(:first)
      @cart = Cart.new(:account => @account)
    end
    
    context "calling ship_to_attrs=" do
      setup do
        @cart.ship_to_attrs = {:line1 => "Line 1 Really"}
      end
      
      should "return the new address object" do
        assert @cart.ship_to.new_record?
      end
      
      should "set the attributes correctly" do
        assert_equal "Line 1 Really", @cart.ship_to.line1
        assert_equal @account.id, @cart.ship_to.account_id
      end
      
      context "and saving the cart" do
        setup do 
          @cart.save!
        end
        
        should "save the ship to address" do
          ship_to = @cart.reload.ship_to
          assert_not_nil ship_to
          assert !ship_to.new_record?
          assert_equal "Line 1 Really", ship_to.line1
          assert_equal @cart.account_id, ship_to.account_id
        end
      end
    end

    context "calling email_attrs=" do
      setup do
        @cart.email_attrs = {:email_address => "test@test.com"}
      end
      
      should "return the new email object" do
        assert @cart.email.new_record?
      end
      
      should "set the attributes correctly" do
        assert_equal "test@test.com", @cart.email.email_address
        assert_equal @account.id, @cart.email.account_id
      end

      context "and saving the cart" do
        setup do 
          @cart.save!
        end
        
        should "save the email" do
          email = @cart.reload.email
          assert_not_nil email
          assert !email.new_record?
          assert_equal "test@test.com", email.email_address
          assert_equal @cart.account_id, email.account_id
        end
      end
    end

    context "calling phone_attrs=" do
      setup do
        @cart.phone_attrs = {:number => "6667778888"}
      end
      
      should "return the new phone object" do
        assert @cart.phone.new_record?
      end
      
      should "set the attributes correctly" do
        assert_equal "6667778888", @cart.phone.number
        assert_equal @account.id, @cart.phone.account_id
      end

      context "and saving the cart" do
        setup do 
          @cart.save!
        end
        
        should "save the phone" do
          phone = @cart.reload.phone
          assert_not_nil phone
          assert !phone.new_record?
          assert_equal "6667778888", phone.number
          assert_equal @cart.account_id, phone.account_id
        end
      end
    end
    
    context "calling invoice_to_attrs=" do
      setup do
        @cart.invoice_to_attrs = {:full_name => "FirstName MiddleName LastName"}
      end
      
      should "return the new party object" do
        assert @cart.invoice_to.new_record?
        assert_equal "Party", @cart.invoice_to.class.name
      end
      
      should "set the attributes correctly" do
        assert_equal "FirstName MiddleName LastName", @cart.invoice_to.name.to_s
        assert_equal @account.id, @cart.invoice_to.account_id
      end

      context "and saving the cart" do
        setup do 
          @cart.save!
        end
        
        should "save the party" do
          invoice_to = @cart.reload.invoice_to
          assert_not_nil invoice_to
          assert !invoice_to.new_record?
          assert_equal "FirstName MiddleName LastName", invoice_to.name.to_s
          assert_equal @cart.account_id, invoice_to.account_id
        end
      end
    end
  end
  
  context "Adding cart routes to the invoice to" do
    setup do
      @cart = Cart.create!(:account => Account.find(:first))
      @cart.update_attributes!(
        :invoice_to_attrs => {:full_name => "FirstName LastName"},
        :email_attrs => {:email_address => "aloha@test.com"},
        :ship_to_attrs => {:line1 => "Line 1 Really"},
        :phone_attrs => {:number => "6667778888"})
      @cart.add_routes_to_invoice_to!
      @cart.reload
    end
    
    should "add contact routes to the party properly" do
      party = @cart.invoice_to
      assert_equal "aloha@test.com", party.main_email.email_address
      assert_equal "Line 1 Really", party.main_address.line1
      assert_equal "6667778888", party.main_phone.number
    end
  end
  
  context "Adding products to a cart" do
    setup do
      @my_fish = products(:fish)
      @my_dog = products(:dog)
      @cart = Cart.create!(:account => Account.find(:first))
      cart_line = CartLine.new(:product => @my_fish, :quantity => 1)
      cart_line.cart = @cart
      cart_line.save!
    end
  
    should "add another product cart line when adding new product" do
      lines_count = @cart.lines.count
      cart_line = @cart.add_product({:product_id => @my_dog.id, :quantity => 2})
      cart_line.save!
      assert_equal lines_count + 1, @cart.lines.size
      assert_equal 2, cart_line.quantity
    end
    
    should "add quantity when adding an existing product" do
      lines_count = @cart.lines.size
      cart_line = @cart.add_product({:product_id => @my_fish.id, :quantity => 2})
      cart_line.save!
      assert_equal lines_count, @cart.lines.size
      assert_equal 3, @cart.lines.first.quantity
    end
  end
  
  context "Destroying a cart" do
    setup do
      @my_fish = products(:fish)
      @my_dog = products(:dog)
      @cart = Cart.create!(:account => Account.find(:first))
      @cart_line = CartLine.new(:product => @my_fish, :quantity => 1)
      @cart_line.cart = @cart
      @cart_line.save!
    end
    
    should "destroy the cart and the cart lines" do
      assert_difference Product, :count, 0 do
        assert_difference Cart, :count, -1 do
          assert_difference CartLine, :count, -1 do
            @cart.destroy
          end
        end
      end
    end
    
    context "with a product of a cart line destroyed" do
      setup do
        @my_fish.destroy
      end
      
      should "still destroy the cart and the cart lines" do
        assert_difference Cart, :count, -1 do
          assert_difference CartLine, :count, -1 do
            @cart.destroy
          end
        end
      end
    end
  end
  
  context "Converting a cart to an order" do
    setup do
      @my_fish = products(:fish)
      @my_dog = products(:dog)
      @cart = Cart.create!(:account => Account.find(:first), :invoice_to => parties(:bob))
      @cart.add_product(:product_id => @my_fish.id, :quantity => 1).save!
      @cart.add_product(:product_id => @my_dog.id, :quantity => 2).save!
      @order_lines_count = OrderLine.count
      @order = @cart.to_order!
    end

    should "copy all cart attributes to the order object" do
      @cart.attributes.each_pair do |key, value|
        next if ["id"].index(key)
        assert_equal value, @order.send(key), "when evaluating #{key}"
      end
    end
    
    should "create order lines correctly" do
      assert_equal @order_lines_count + 2, OrderLine.count
      assert_not_nil fish_line=@order.lines.find_by_product_id(@my_fish.id)
      assert_equal 1, fish_line.quantity
      assert_not_nil dog_line=@order.lines.find_by_product_id(@my_dog.id)
      assert_equal 2, dog_line.quantity      
    end
  end
end
