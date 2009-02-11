require File.dirname(__FILE__) + '/../test_helper'

class PaymentTermTest < Test::Unit::TestCase
  def setup
    @account = accounts(:wpul)
  end

  context "A new PaymentTerm" do
    should "return 'n/30' when no percent and 30 days" do
      pt = @account.payment_terms.create!(:days => 30)
      assert_equal "n/30", pt.to_s
    end

    should "return 2/30 when 2% and 30 days" do
      pt = @account.payment_terms.create!(:percent => 2, :days => 30)
      assert_equal "2/30", pt.to_s
    end

    should "return '2/30, n/30' when composed of two child payment terms" do
      pt0 = @account.payment_terms.create!(:percent => 2, :days => 10)
      pt1 = @account.payment_terms.create!(:days => 30)
      pt2 = @account.payment_terms.create!
      pt2.children << pt0 << pt1
      assert_equal "2/10, n/30", pt2.to_s
    end
  end

  context "PaymentTerm#parse" do
    should "return nil when parsing the empty string" do
      assert_nil PaymentTerm.parse("")
    end

    should "return nil when parsing nil" do
      assert_nil PaymentTerm.parse(nil)
    end

    should "return a leaf PaymentTerm equal to n/30 when parsing 'n/30'" do
      pt = nil
      assert_difference PaymentTerm, :count, 1 do
        pt = @account.payment_terms.parse("n/30")
      end

      assert_not_nil pt
      assert_equal "n/30", pt.to_s
    end

    should "return an existing leaf PaymentTerm to 2/10 when parsing '2/10'" do
      original = @account.payment_terms.create!(:days => 10, :percent => 2)
      pt = nil
      assert_difference PaymentTerm, :count, 0 do
        pt = @account.payment_terms.parse("2/10")
      end

      assert_equal original, pt
    end

    should "return a composite PaymentTerm for '2/10, n/30'" do
      pt = nil
      assert_difference PaymentTerm, :count, 3 do
        pt = @account.payment_terms.parse("2/10, n/30")
      end

      assert_equal "2/10, n/30", pt.to_s
    end

    should "return an existing composite PaymentTerm for '2/10, n/30'" do
      original = @account.payment_terms.parse("2/10, n/30")
      pt = nil
      assert_difference PaymentTerm, :count, 0 do
        pt = @account.payment_terms.parse("2/10, n/30")
      end

      assert_equal original, pt
    end
  end
end
