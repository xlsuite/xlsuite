#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PaymentTerm < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id

  belongs_to :parent, :class_name => "PaymentTerm", :foreign_key => "parent_id"
  has_many :children, :class_name => "PaymentTerm", :foreign_key => "parent_id", :order => "days"

  def to_s
    children.empty? ?  "#{percent || 'n'}/#{days}" : children.map(&:to_s).join(", ")
  end

  def <=>(other)
    days <=> other.days
  end

  class << self
    def parse(text)
      return nil if text.blank?
      parts = text.split(",")
      if parts.size == 1 then
        percent, days = text.strip.split("/", 2)
        percent = (percent == "n" ? nil : Integer(percent))
        days = Integer(days)
        PaymentTerm.find_or_create_by_percent_and_days(percent, days)
      else
        children = parts.map {|part| PaymentTerm.parse(part)}.sort
        rule = children.map(&:to_s).join(", ")
        PaymentTerm.find(:all, :conditions => {:days => nil, :percent => nil}).detect {|pt| rule == pt.to_s}.if_nil {PaymentTerm.create!(:children => children)}
      end
    end
  end
end
