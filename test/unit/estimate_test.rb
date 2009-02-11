require File.dirname(__FILE__) + '/../test_helper'

class EstimateTest < Test::Unit::TestCase
  def setup
    @account = Account.find(1)
  end

  context "An estimate with a ship to" do
    setup do
      @geo = Geocode.create!(:zip => "J1G3N4", :latitude => 45.407955, :longitude => -71.841872)
      logger.debug {"==> Building estimate"}
      @estimate = @account.estimates.build(:date => Date.today, :invoice_to => parties(:bob))
      logger.debug {"==> Building ship to"}
      @estimate.build_ship_to(:zip => "J1G3N4")
      logger.debug {"==> Saving estimate"}
      @estimate.save!
      logger.debug {"==> Estimate saved"}
    end

    should "have a latitude" do
      assert_not_nil @estimate.reload.latitude
    end

    should "have a longitude" do
      assert_not_nil @estimate.reload.longitude
    end

    should "receive the address' latitude" do
      assert_equal @estimate.ship_to.latitude, @estimate.reload.latitude
    end

    should "receive the address' longitude" do
      assert_equal @estimate.ship_to.longitude, @estimate.reload.longitude
    end

    should "find just the address" do
      assert_include @estimate.ship_to, AddressContactRoute.nearest(@geo.latitude, @geo.longitude)
    end

    should "be near a point through the original account" do
      assert_include @estimate, @account.estimates.nearest(@geo.latitude, @geo.longitude)
    end

    should "return the distance in the estimate when finding nearest" do
      assert_not_nil @account.estimates.nearest(@geo.latitude, @geo.longitude).first.distance
    end

    should "return the distance in the estimate when finding within" do
      assert_not_nil @account.estimates.within(50, :unit => :km, :latitude => @geo.latitude, :longitude => @geo.longitude).first.distance
    end

    should "be within a point through the original account" do
      assert_include @estimate, @account.estimates.within(10, :unit => :miles, :latitude => @geo.latitude, :longitude => @geo.longitude)
    end

    should "NOT be near a point through another account" do
      other_account = create_account
      assert_not_include @estimate, other_account.estimates.nearest(@geo.latitude, @geo.longitude)
    end

    should "NOT be within a point through another account" do
      other_account = create_account
      assert_not_include @estimate, other_account.estimates.within(20, :unit => :km, :latitude => @geo.latitude, :longitude => @geo.longitude)
    end
  end

  context "An estimate" do
    setup do
      @estimate = @account.estimates.build(
      :fst_name => "FST", :fst_rate => 0, :fst_active => false, :apply_fst_on_labor => false, :apply_fst_on_products => false,
      :pst_name => "PST", :pst_rate => 0, :pst_active => false, :apply_pst_on_labor => false, :apply_pst_on_products => false,
      :shipping_fee => Money.zero("CAD"), :equipment_fee => Money.zero("CAD"), :transport_fee => Money.zero("CAD"),
      :date => Date.today, :invoice_to => parties(:bob)
      )
    end

    should "have a zero subtotal" do
      assert_equal Money.zero("CAD"), @estimate.subtotal_amount
    end

    should "have a zero shipping fee" do
      assert_equal Money.zero("CAD"), @estimate.shipping_fee
    end

    should "have a zero transport fee" do
      assert_equal Money.zero("CAD"), @estimate.transport_fee
    end

    should "have a zero equipment fee" do
      assert_equal Money.zero("CAD"), @estimate.equipment_fee
    end

    should "have a zero fst amount" do
      assert_equal Money.zero("CAD"), @estimate.fst_amount
    end

    should "have a zero pst amount" do
      assert_equal Money.zero("CAD"), @estimate.pst_amount
    end

    should "have a zero total amount" do
      assert_equal Money.zero("CAD"), @estimate.total_amount
    end

    should "have a zero labor amount" do
      assert_equal Money.zero("CAD"), @estimate.labor_amount
    end

    should "have a zero product amount" do
      assert_equal Money.zero("CAD"), @estimate.products_amount
    end

    context "with a single product line" do
      setup do
        @estimate.lines.build(:product => products(:fish), :retail_price => "2.50 CAD", :quantity => 3)
      end

      should "have a 7.50 CAD total" do
        assert_equal "7.50 CAD".to_money, @estimate.total_amount
      end

      should "have a 7.50 CAD subtotal" do
        assert_equal "7.50 CAD".to_money, @estimate.subtotal_amount
      end

      should "have a 7.50 CAD product amount" do
        assert_equal "7.50 CAD".to_money, @estimate.products_amount
      end

      should "have a zero shipping fee" do
        assert_equal Money.zero("CAD"), @estimate.shipping_fee
      end

      should "have a zero transport fee" do
        assert_equal Money.zero("CAD"), @estimate.transport_fee
      end

      should "have a zero equipment fee" do
        assert_equal Money.zero("CAD"), @estimate.equipment_fee
      end

      should "have a zero fst amount" do
        assert_equal Money.zero("CAD"), @estimate.fst_amount
      end

      should "have a zero pst amount" do
        assert_equal Money.zero("CAD"), @estimate.pst_amount
      end

      should "have a zero labor amount" do
        assert_equal Money.zero("CAD"), @estimate.labor_amount
      end
    end

    context "with a single labor line" do
      setup do
        @estimate.lines.build(:retail_price => "3.30 CAD", :quantity => 2)
      end

      should "have a 6.60 CAD total" do
        assert_equal "6.60 CAD".to_money, @estimate.total_amount
      end

      should "have a 6.60 CAD subtotal" do
        assert_equal "6.60 CAD".to_money, @estimate.subtotal_amount
      end

      should "have a 6.60 CAD labor amount" do
        assert_equal "6.60 CAD".to_money, @estimate.labor_amount
      end

      should "have a zero shipping fee" do
        assert_equal Money.zero("CAD"), @estimate.shipping_fee
      end

      should "have a zero transport fee" do
        assert_equal Money.zero("CAD"), @estimate.transport_fee
      end

      should "have a zero equipment fee" do
        assert_equal Money.zero("CAD"), @estimate.equipment_fee
      end

      should "have a zero fst amount" do
        assert_equal Money.zero("CAD"), @estimate.fst_amount
      end

      should "have a zero pst amount" do
        assert_equal Money.zero("CAD"), @estimate.pst_amount
      end

      should "have a zero product amount" do
        assert_equal Money.zero("CAD"), @estimate.products_amount
      end
    end

    context "with product and labor lines" do
      setup do
        @estimate.lines.build(:product => products(:fish), :retail_price => "4.25 CAD", :quantity => 2)
        @estimate.lines.build(:retail_price => "1.99 CAD", :quantity => 1)

        @total = "4.25 CAD".to_money * 2 + "1.99 CAD".to_money
      end

      should "have a (2*4.25 + 1.99) subtotal" do
        assert_equal @total, @estimate.subtotal_amount
      end

      should "have a zero shipping fee" do
        assert_equal Money.zero("CAD"), @estimate.shipping_fee
      end

      should "have a zero transport fee" do
        assert_equal Money.zero("CAD"), @estimate.transport_fee
      end

      should "have a zero equipment fee" do
        assert_equal Money.zero("CAD"), @estimate.equipment_fee
      end

      should "have a zero fst amount" do
        assert_equal Money.zero("CAD"), @estimate.fst_amount
      end

      should "have a zero pst amount" do
        assert_equal Money.zero("CAD"), @estimate.pst_amount
      end

      should "have a (2*4.25 + 1.99) total amount" do
        assert_equal @total, @estimate.total_amount
      end

      should "have a 1.99 labor amount" do
        assert_equal "1.99 CAD".to_money, @estimate.labor_amount
      end

      should "have a 2*4.25 product amount" do
        assert_equal "4.25 CAD".to_money * 2, @estimate.products_amount
      end

      context "and 5% FST on both labor and products" do
        setup do
          @estimate.fst_active = true
          @estimate.apply_fst_on_products = true
          @estimate.apply_fst_on_labor = true
          @estimate.fst_rate = 5
        end

        should "have a (2*4.25 + 1.99) subtotal" do
          assert_equal @total, @estimate.subtotal_amount
        end

        should "have a 1.99 labor amount" do
          assert_equal "1.99 CAD".to_money, @estimate.labor_amount
        end

        should "have a 2*4.25 product amount" do
          assert_equal "4.25 CAD".to_money * 2, @estimate.products_amount
        end

        should "have a zero shipping fee" do
          assert_equal Money.zero("CAD"), @estimate.shipping_fee
        end

        should "have a zero transport fee" do
          assert_equal Money.zero("CAD"), @estimate.transport_fee
        end

        should "have a zero equipment fee" do
          assert_equal Money.zero("CAD"), @estimate.equipment_fee
        end

        should "have a ((2*4.25 + 1.99) * 0.05) fst amount" do
          # Tax calculations are rounded.  10.49 * 0.05 = 0.5245 = 0.52 CAD rounded
          assert_equal "0.52 CAD".to_money, @estimate.fst_amount
        end

        should "have a zero pst amount" do
          assert_equal Money.zero("CAD"), @estimate.pst_amount
        end

        should "have a (2*4.25 + 1.99) + ((2*4.25 + 1.99) * 0.05) total" do
          assert_equal @total + @total * 0.05, @estimate.total_amount
        end
      end

      context "and 8% PST on both labor and products" do
        setup do
          @estimate.pst_active = true
          @estimate.apply_pst_on_products = true
          @estimate.apply_pst_on_labor = true
          @estimate.pst_rate = 8
        end

        should "have a (2*4.25 + 1.99) subtotal" do
          assert_equal @total, @estimate.subtotal_amount
        end

        should "have a 1.99 labor amount" do
          assert_equal "1.99 CAD".to_money, @estimate.labor_amount
        end

        should "have a 2*4.25 product amount" do
          assert_equal "4.25 CAD".to_money * 2, @estimate.products_amount
        end

        should "have a zero shipping fee" do
          assert_equal Money.zero("CAD"), @estimate.shipping_fee
        end

        should "have a zero transport fee" do
          assert_equal Money.zero("CAD"), @estimate.transport_fee
        end

        should "have a zero equipment fee" do
          assert_equal Money.zero("CAD"), @estimate.equipment_fee
        end

        should "have a zero fst amount" do
          assert_equal Money.zero("CAD"), @estimate.fst_amount
        end

        should "have a ((2*4.25 + 1.99) * 0.08) pst amount" do
          # Tax calculations are rounded.  10.49 * 0.08 = 0.8392 = 0.84 CAD rounded
          assert_equal "0.84 CAD".to_money, @estimate.pst_amount
        end

        should "have a (2*4.25 + 1.99) + ((2*4.25 + 1.99) * 0.08) total" do
          assert_equal @total + @total * 0.08, @estimate.total_amount
        end
      end

      context "and a 5% FST on labor + 8% PST on products" do
        setup do
          @estimate.fst_active = true
          @estimate.apply_fst_on_products = false
          @estimate.apply_fst_on_labor = true
          @estimate.fst_rate = 5

          @estimate.pst_active = true
          @estimate.apply_pst_on_products = true
          @estimate.apply_pst_on_labor = false
          @estimate.pst_rate = 8
        end

        should "have a (2*4.25 + 1.99) subtotal" do
          assert_equal @total, @estimate.subtotal_amount
        end

        should "have a 1.99 labor amount" do
          assert_equal "1.99 CAD".to_money, @estimate.labor_amount
        end

        should "have a 2*4.25 product amount" do
          assert_equal "4.25 CAD".to_money * 2, @estimate.products_amount
        end

        should "have a zero shipping fee" do
          assert_equal Money.zero("CAD"), @estimate.shipping_fee
        end

        should "have a zero transport fee" do
          assert_equal Money.zero("CAD"), @estimate.transport_fee
        end

        should "have a zero equipment fee" do
          assert_equal Money.zero("CAD"), @estimate.equipment_fee
        end

        should "have a (1.99 * 0.05) fst amount" do
          # 1.99 * 0.05 = 0.0995 = 0.10
          assert_equal "0.10 CAD".to_money, @estimate.fst_amount
        end

        should "have a (2*4.25 * 0.08) pst amount" do
          # 8.50 * 0.08 = 0.68
          assert_equal "0.68 CAD".to_money, @estimate.pst_amount
        end

        should "have a (2*4.25 + 1.99) + (2*4.25*0.05 + 1.99*0.05) total" do
          assert_equal @total + "0.10 CAD".to_money + "0.68 CAD".to_money, @estimate.total_amount
        end
      end
    end

    context "with 5% FST and 6% PST on both labor and products" do
      setup do
        @estimate.fst_active = true
        @estimate.apply_fst_on_products = true
        @estimate.apply_fst_on_labor = true
        @estimate.fst_rate = 5

        @estimate.pst_active = true
        @estimate.apply_pst_on_products = true
        @estimate.apply_pst_on_labor = true
        @estimate.pst_rate = 6
      end

      context "and 75 CAD of shipping fee" do
        setup do
          @estimate.shipping_fee = "75 CAD".to_money
        end

        should "have a zero subtotal" do
          assert_equal Money.zero("CAD"), @estimate.subtotal_amount
        end

        should "include the shipping fee in the fst subtotal" do
          assert_equal "75 CAD".to_money, @estimate.fst_subtotal_amount
        end

        should "include the shipping fee in the fst amount" do
          # 75 * 0.05 = 3.75
          assert_equal "3.75 CAD".to_money, @estimate.fst_amount
        end

        should "include the shipping fee in the pst subtotal" do
          assert_equal "75 CAD".to_money, @estimate.pst_subtotal_amount
        end

        should "include the shipping fee in the pst amount" do
          # 75 * 0.06 = 4.50
          assert_equal "4.50 CAD".to_money, @estimate.pst_amount
        end

        should "include the shipping fee and taxes in the total amount" do
          assert_equal "75 CAD".to_money + "3.75 CAD".to_money + "4.50 CAD".to_money, @estimate.total_amount
        end
      end

      context "and 125 CAD of equipment fee" do
        setup do
          @estimate.equipment_fee = "125 CAD".to_money
        end

        should "have a zero subtotal" do
          assert_equal Money.zero("CAD"), @estimate.subtotal_amount
        end

        should "include the equipment fee in the fst subtotal" do
          assert_equal "125 CAD".to_money, @estimate.fst_subtotal_amount
        end

        should "include the equipment fee in the fst amount" do
          # 125 * 0.05 = 6.25
          assert_equal "6.25 CAD".to_money, @estimate.fst_amount
        end

        should "include the equipment fee in the pst subtotal" do
          assert_equal "125 CAD".to_money, @estimate.pst_subtotal_amount
        end

        should "include the equipment fee in the pst amount" do
          # 125 * 0.06 = 7.50
          assert_equal "7.50 CAD".to_money, @estimate.pst_amount
        end

        should "include the equipment fee and taxes in the total amount" do
          assert_equal "125 CAD".to_money + "6.25 CAD".to_money + "7.50 CAD".to_money, @estimate.total_amount
        end
      end

      context "and 80 CAD of transport fee" do
        setup do
          @estimate.transport_fee = "80 CAD".to_money
        end

        should "have a zero subtotal" do
          assert_equal Money.zero("CAD"), @estimate.subtotal_amount
        end

        should "include the transport fee in the fst subtotal" do
          assert_equal "80 CAD".to_money, @estimate.fst_subtotal_amount
        end

        should "include the transport fee in the fst amount" do
          # 80 * 0.05 = 4
          assert_equal "4 CAD".to_money, @estimate.fst_amount
        end

        should "include the transport fee in the pst subtotal" do
          assert_equal "80 CAD".to_money, @estimate.pst_subtotal_amount
        end

        should "include the transport fee in the pst amount" do
          # 80 * 0.06 = 4.80
          assert_equal "4.80 CAD".to_money, @estimate.pst_amount
        end

        should "include the transport fee and taxes in the total amount" do
          assert_equal "80 CAD".to_money + "4 CAD".to_money + "4.80 CAD".to_money, @estimate.total_amount
        end
      end
    end

    context "with 'the works' (taxes, fees, labor and product lines)" do
      setup do
        @estimate.lines.build(:product => products(:fish), :quantity => 3, :retail_price => "3.99 CAD".to_money)
        @estimate.lines.build(:quantity => 7, :retail_price => "49.99 CAD".to_money)

        @estimate.shipping_fee = "75 CAD".to_money
        @estimate.transport_fee = "50 CAD".to_money
        @estimate.equipment_fee = "125 CAD".to_money

        @estimate.fst_active = true
        @estimate.apply_fst_on_products = true
        @estimate.apply_fst_on_labor = true
        @estimate.fst_rate = 5

        @estimate.pst_active = true
        @estimate.apply_pst_on_products = true
        @estimate.apply_pst_on_labor = true
        @estimate.pst_rate = 6
      end

      should "calculate the fees FST amount using only the fees" do
        assert_equal ["75 CAD", "50 CAD", "125 CAD"].map(&:to_money).sum * 0.05, @estimate.fees_fst_amount
      end

      should "calculate the fees PST amount using only the fees" do
        assert_equal ["75 CAD", "50 CAD", "125 CAD"].map(&:to_money).sum * 0.06, @estimate.fees_pst_amount
      end

      should "only include the lines in the subtotal" do
        assert_equal "49.99 CAD".to_money.to_money * 7 + "3.99 CAD".to_money * 3, @estimate.subtotal_amount
      end

      should "include the lines and fees in #subtotal_and_fees" do
        assert_equal "49.99 CAD".to_money.to_money * 7 + "3.99 CAD".to_money * 3 + "75 CAD".to_money + "50 CAD".to_money + "125 CAD".to_money, @estimate.subtotal_and_fees_amount
      end

      should "NOT include the lines in the fees amount" do
        assert_equal "75 CAD".to_money + "50 CAD".to_money + "125 CAD".to_money, @estimate.fees_amount
      end

      should "NOT include the fees in labor_amount" do
        assert_equal "49.99 CAD".to_money * 7, @estimate.labor_amount
      end

      should "NOT include the fees in products_amount" do
        assert_equal "3.99 CAD".to_money * 3, @estimate.products_amount
      end
    end
  end

  context "Making payment to an estimate" do
    setup do
      @estimate = create_estimate
      @estimate.lines.create!(:quantity => 2, :retail_price => Money.new(1500), :product => Product.find(:first))
      assert_equal false, @estimate.paid_in_full?
    end
  
    context "using Paypal" do
      setup do
        @payment_method = "paypal"
      end
  
      context "that has been paid in full" do
        setup do
          @payment = @estimate.make_payment!(@payment_method)
          @payable = Payable.find_by_payment_id(@payment.id)
          assert_equal false, @estimate.paid_in_full?
          PaymentHelper.new.complete!(@payable, parties(:bob))
          assert_equal true, @estimate.paid_in_full?
        end
  
        should "raise HasBeenPaidInFull exception when trying to start the payment" do
          assert_raise XlSuite::PaymentSystem::HasBeenPaidInFull do
            @payment.start!(parties(:bob))
          end
        end
  
        should "raise HasBeenPaidInFull exception when trying to create another payment" do
          assert_raise XlSuite::PaymentSystem::HasBeenPaidInFull do
            @estimate.make_payment!(@payment_method)
          end
        end
      end
    end
  end
  
  context "An estimate with custom column" do
    setup do
      @estimate = @account.estimates.build
    end
  
    should "accept writes" do
      assert_nothing_raised do
        @estimate.bushes_product_id = 1234
      end
    end
  
    should "return the stored value" do
      @estimate.normal = true
      assert_equal true, @estimate.normal
    end
  
    should "survive a reload" do
      @estimate.kryptonite_quality = :high
      @estimate.save(false)
      assert_equal :high, Estimate.find(@estimate.id).kryptonite_quality
    end
  end
  
  context "Creating an estimate" do
    context "with :email set to a String" do
      should "create an EmailContactRoute" do
        assert_difference EmailContactRoute, :count, 1 do
          Estimate.create!(:email => "frodo@baggins.com", :account => accounts(:wpul), :invoice_to => parties(:bob), :date => Date.today)
        end
      end
    end
  end
end
