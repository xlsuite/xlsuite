require File.dirname(__FILE__) + '/../test_helper'

class OrderLineTest < Test::Unit::TestCase
  setup do
    @account = Account.find(:first)
  end

  context "A new order line" do
    setup do
      @order_line = OrderLine.new
    end

    should "want to show when quantity is 1" do
      @order_line.quantity = BigDecimal.new("1.0")
      assert @order_line.show?
    end

    should "want to show when quantity is -1" do
      @order_line.quantity = BigDecimal.new("-1.0")
      assert @order_line.show?
    end

    should "NOT want to show when quantity is 0" do
      @order_line.quantity = BigDecimal.new("0")
      deny @order_line.show?
    end
  end

  context "A new order line initialized without any parameter" do
    setup do
      @order_line = OrderLine.new
    end
    
    should "have 1.0 as quantity" do
      assert_equal BigDecimal.new("1.0"), @order_line.quantity
    end
  end
  
  context "A new order line, where '15 chf' is set as the unit price" do
    setup do
      @order_line = OrderLine.new(:retail_price => "15 chf")
    end

    should "set the unit price to a Money instance" do
      assert_kind_of Money, @order_line.retail_price
    end

    should "set the unit price to an equivalent Money instance" do
      assert_equal "15 CHF".to_money, @order_line.retail_price
    end
  end

  context "An existing product order line" do
    setup do
      @product = products(:fish)
      @order = @account.orders.create!(:invoice_to => parties(:bob), :date => Time.now)
      @order_line = @order.lines.create!(:product => @product, :quantity => 2.0)
    end

    should "have a unit price equal to product's unit price" do
      assert_equal @product.retail_price, @order_line.retail_price
    end

    should "have a description equal to product's name" do
      assert_equal @product.name, @order_line.description
    end

    should "have a SKU equal to product's SKU" do
      assert_equal @product.sku, @order_line.sku
    end

    should "not change the SKU when the product's SKU changes" do
      osku = @order_line.sku

      @product.sku = @product.sku * 2
      @product.save!

      assert_equal osku, @order_line.reload.sku
    end

    should "not change the description when the product's name changes" do
      oname = @order_line.description

      @product.name = @product.name * 2
      @product.save!

      assert_equal oname, @order_line.reload.description
    end

    should "not change the retail price when the product's retail price changes" do
      oprice = @order_line.retail_price

      @product.retail_price = @product.retail_price * 2
      @product.save!

      assert_equal oprice, @order_line.reload.retail_price
    end
    
    context "about to be destroyed" do
      setup do
        assert_equal false, @order_line.destroy
      end
      
      should "not be destroyed" do
        @order_line.reload
      end
      
      should "have its quantity set to 0.0" do
        assert_equal BigDecimal.new("0.0"), @order_line.quantity
      end
    end
    
    context "after invoiced" do
      setup do
        @order_line.update_attribute(:quantity_invoiced, BigDecimal.new("2.0"))
      end
      
      should "lock its retail price attribute" do
        @order_line.retail_price = @product.retail_price + Money.new(1000)
        assert_equal false, @order_line.save
        assert_equal @product.retail_price, @order_line.reload.retail_price
      end
    end
  end

  context "A new product line with a blank unit price, description and a SKU" do
    setup do
      @product = products(:fish)
      @order_line = OrderLine.new(:retail_price => "", :sku => "", :description => "", :product => @product)
      @order_line.save(false)
    end

    should "copy the product's retail price" do
      assert_equal @product.retail_price, @order_line.retail_price
    end

    should "copy the product's name" do
      assert_equal @product.name, @order_line.description
    end

    should "copy the product's SKU" do
      assert_equal @product.sku, @order_line.sku
    end
  end

  context "A new product line with a unit price, description and a SKU" do
    setup do
      @order_line = OrderLine.new(:retail_price => 141.to_money, :sku => "K999",
                                         :description => "my custom description", :product => products(:fish))
      @order_line.save(false)
    end

    should "not overwrite the custom unit price" do
      assert_equal 141.to_money, @order_line.retail_price
    end

    should "not overwrite the custom description" do
      assert_equal "my custom description", @order_line.description
    end

    should "not overwrite the custom SKU" do
      assert_equal "K999", @order_line.sku
    end
  end
end
