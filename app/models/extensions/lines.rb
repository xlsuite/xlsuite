#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

# A module that extends all Cart#lines, Order#lines and Invoice#lines.
module Extensions
  module Lines
    def products
      return [] if self.compact.empty?
      if self.first.new_record?
        self.select {|e| e.product_id != nil}
      else
        find(:all, :conditions => ["product_id IS NOT NULL"])
      end
    end

    def labor
      return [] if self.compact.empty?
      if self.first.new_record?
        # TODO: I don't think this condition is good anymore
        self.select {|e| e.product_id == nil}
      else
        find(:all, :conditions => ["product_id IS NULL"])
      end
    end

    def comments
      return [] if self.compact.empty?
      if self.first.new_record?
        # TODO: I don't think this condition is good anymore
        self.select {|e| e.product_id == nil && (quantity == nil || e.quantity < 1)}
      else
        find(:all, :conditions => ["product_id IS NULL AND (quantity IS NULL OR quantity < 1)"])
      end
    end
  end
end
