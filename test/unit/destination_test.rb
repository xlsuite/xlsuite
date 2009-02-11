require File.dirname(__FILE__) + '/../test_helper'

class DestinationTest < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
    @account.destinations.create({:country=>"CAN", :state=>"BC", :cost=>1000.to_money})
    @account.destinations.create({:country=>"CAN", :cost=>2000.to_money})
    @account.destinations.create({:country=>"All Others", :cost=>3000.to_money})
  end
  
  def test_shipping_cost_for_canada_bc
    assert_equal 1000.to_money, @account.destinations.shipping_cost_for_country_and_state("can", "bc")
  end
  
  def test_shipping_cost_for_canada
    assert_equal 2000.to_money, @account.destinations.shipping_cost_for_country_and_state("can")
    assert_equal 2000.to_money, @account.destinations.shipping_cost_for_country_and_state("can", nil)
    assert_equal 2000.to_money, @account.destinations.shipping_cost_for_country_and_state("can", "")
  end
  
  def test_shipping_cost_foro_canada_qc
    assert_equal 2000.to_money, @account.destinations.shipping_cost_for_country_and_state("can", "qc")
  end
  
  def test_shipping_cost_for_usa_ala
    assert_equal 3000.to_money, @account.destinations.shipping_cost_for_country_and_state("usa", "al")
  end
  
  def test_shipping_cost_for_invalid
    assert_equal 3000.to_money, @account.destinations.shipping_cost_for_country_and_state(nil, nil)
    assert_equal 3000.to_money, @account.destinations.shipping_cost_for_country_and_state(nil, "BC")
    assert_equal 3000.to_money, @account.destinations.shipping_cost_for_country_and_state("", "")
    assert_equal 3000.to_money, @account.destinations.shipping_cost_for_country_and_state()
  end
  
end