require File.dirname(__FILE__) + "/test_helper"

class MoneyExtensionsTest < Test::Unit::TestCase
  def test_zero
    assert_equal Money.new(0, "CAD"), Money.zero("CAD")
    assert_equal Money.new(0, "USD"), Money.zero("USD")
  end

  def test_penny
    assert_equal Money.new(1, "CAD"), Money.penny("CAD")
    assert_equal Money.new(1, "USD"), Money.penny("USD")
  end

  def test_rounding
    assert_equal Money.new(2.5.round, "CAD"), Money.new(2.5, "CAD").round
  end

  def test_absoluting
    assert_equal Money.new(-3.abs, "CAD"), Money.new(-3, "CAD").abs
  end

  def test_ceiling
    assert_equal Money.new(2.5.ceil, "CAD"), Money.new(2.5, "CAD").ceil
  end

  def test_zero?
    assert Money.zero.zero?
    assert_equal false, Money.penny.zero?
  end

  def test_integer_money
    assert_equal Money.new(15, "CAD"), 15.to_money("CAD")
    assert_equal Money.new(1499, "USD"), 1499.to_money("USD")
  end

  def test_float_money
    assert_equal Money.new(1500, "CAD"), 15.0.to_money("CAD")
    assert_equal Money.new(1499, "USD"), 14.99.to_money("USD")
  end

  def test_string_money
    assert_equal Money.new(1500, "CAD"), "15 CAD".to_money
    assert_equal Money.new(1499, "USD"), "usd 14.99".to_money
  end

  def test_round_to_nearest_dollar
    assert_equal Money.new(1500, "CAD"), "14.53 cad".to_money.round_to_nearest_dollar
  end

  def test_formatting
    assert_equal "", Money.zero.format
    assert_equal "$1.01", "1.01 CAD".to_money.format
  end
end
