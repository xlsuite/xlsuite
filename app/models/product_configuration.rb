#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ProductConfiguration < Configuration
  belongs_to :product

  def value() self.product; end
  def set_value!(val)
    self.product =
        if val.kind_of?(Product)                            then val
        elsif val.blank?                                    then nil
        elsif val.kind_of?(String) or val.kind_of?(Numeric) then Product.find(val)
        else
          raise "Don't know how to transform from #{val.class} to Product"
        end
    self.save!
  end
end
