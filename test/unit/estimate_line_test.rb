require File.dirname(__FILE__) + '/../test_helper'

class EstimateLineTest < Test::Unit::TestCase
  context "A new estimate line" do
    setup do
      @estimate_line = EstimateLine.new
    end

    should "want to show when quantity is 1" do
      @estimate_line.quantity = BigDecimal.new("1.0")
      assert @estimate_line.show?
    end

    should "want to show when quantity is -1" do
      @estimate_line.quantity = BigDecimal.new("-1.0")
      assert @estimate_line.show?
    end

    should "NOT want to show when quantity is 0" do
      @estimate_line.quantity = BigDecimal.new("0")
      deny @estimate_line.show?
    end

    should "have a default quantity of 1" do
      assert_equal 1, @estimate_line.quantity
    end
  end

  context "A new estimate line, where '15 chf' is set as the retail price" do
    setup do
      @estimate_line = EstimateLine.new(:retail_price => "15 chf")
    end

    should "set the retail price to a Money instance" do
      assert_kind_of Money, @estimate_line.retail_price
    end

    should "set the retail price to an equivalent Money instance" do
      assert_equal "15 CHF".to_money, @estimate_line.retail_price
    end
  end

  context "An existing product estimate line" do
    setup do
      @product = products(:fish)
      @estimate = accounts(:wpul).estimates.create!(:invoice_to => parties(:bob), :date => Time.now)
      @estimate_line = @estimate.lines.create!(:product => @product, :quantity => 2.0)
    end

    should "copy the product's retail price" do
      assert_equal @product.retail_price, @estimate_line.retail_price
    end

    should "copy the product's name as the line's description" do
      assert_equal @product.name, @estimate_line.description
    end

    should "copy the product's SKU" do
      assert_equal @product.sku, @estimate_line.sku
    end

    should "NOT change the SKU when the product's SKU changes" do
      osku = @estimate_line.sku

      @product.sku = @product.sku * 2
      @product.save!

      assert_equal osku, @estimate_line.reload.sku
    end

    should "NOT change the description when the product's name changes" do
      oname = @estimate_line.description

      @product.name = @product.name * 2
      @product.save!

      assert_equal oname, @estimate_line.reload.description
    end

    should "NOT change the retail price when the product's retail price changes" do
      oprice = @estimate_line.retail_price

      @product.retail_price = @product.retail_price * 2
      @product.save!

      assert_equal oprice, @estimate_line.reload.retail_price
    end
  end

  context "A new product line with a blank retail price, description and a SKU" do
    setup do
      @product = products(:fish)
      @estimate_line = EstimateLine.new(:retail_price => "", :sku => "", :description => "", :product => @product)
      @estimate_line.save(false)
    end

    should "copy the product's retail price" do
      assert_equal @product.retail_price, @estimate_line.retail_price
    end

    should "copy the product's name" do
      assert_equal @product.name, @estimate_line.description
    end

    should "copy the product's SKU" do
      assert_equal @product.sku, @estimate_line.sku
    end

    should "copy the product's name as the line's description" do
      assert_equal @product.name, @estimate_line.description
    end
  end

  context "A new product line with a retail price, description and a SKU" do
    setup do
      @estimate_line = EstimateLine.new(:retail_price => 141.to_money, :sku => "K999",
      :description => "my custom description", :product => products(:fish))
      @estimate_line.save(false)
    end

    should "not overwrite the custom retail price" do
      assert_equal 141.to_money, @estimate_line.retail_price
    end

    should "not overwrite the custom description" do
      assert_equal "my custom description", @estimate_line.description
    end

    should "not overwrite the custom SKU" do
      assert_equal "K999", @estimate_line.sku
    end

    should "NOT overwrite the custom description" do
      assert_equal "my custom description", @estimate_line.description
    end
  end
end
