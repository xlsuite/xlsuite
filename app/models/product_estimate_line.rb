#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ProductEstimateLine < EstimateLine
  belongs_to :product

  def product?; true; end

  def no
    self.product.product_no
  end

  def description
    self.comment.blank? ? self.product.name : self.comment
  end
  
  def main_identifier
    "#{self.estimate.main_identifier} : #{self.description}"
  end
end
