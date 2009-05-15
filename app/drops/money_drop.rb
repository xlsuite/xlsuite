#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class MoneyDrop < Liquid::Drop
  delegate :to_s, :cents, :to => :money
  attr_reader :money

  def initialize(money)
    @money = money
  end

  def to_formatted_s
    price = self.money.format(:no_cents, :with_currency)
    num = price.slice!(/\d+/)
    return "No info" if num.nil?
    price[0..0] << num.reverse.scan(/\d{1,3}/).join(',').reverse << price[1..-1]
  end
  
  def to_no_currency_s
    price = self.money.format(:no_cents)
    num = price.slice!(/\d+/)
    return "No info" if num.nil?
    price[0..0] << num.reverse.scan(/\d{1,3}/).join(',').reverse << price[1..-1]
  end
  
  def dollar
    self.money.cents / 100
  end
  
  def dollar_round_up
    f=self.money.cents / 100.0
    f.ceil
  end
end
