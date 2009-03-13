#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Hash
  def nested_stringify_keys!
    self.stringify_keys!
    self.keys.each do |k|
      self[k].nested_stringify_keys! if self[k].kind_of?(Hash)
    end

    nil
  end
end
