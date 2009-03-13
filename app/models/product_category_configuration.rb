#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ProductCategoryConfiguration < Configuration
  belongs_to :product_category

  def value() self.product_category; end
  def set_value!(val)
    self.product_category =
        if val.kind_of?(ProductCategory)                    then val
        elsif val.blank?                                    then nil
        elsif val.kind_of?(Numeric) then ProductCategory.find(val)
        else
          raise "Don't know how to transform from #{val.class} to ProductCategory"
        end
    self.save!
  end
end
