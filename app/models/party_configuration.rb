#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PartyConfiguration < Configuration
  belongs_to :party

  def value() self.party; end
  def set_value!(val)
    self.party =
        if val.kind_of?(Party)                              then val
        elsif val.blank?                                    then nil
        elsif val.kind_of?(String) or val.kind_of?(Numeric) then Party.find(val)
        else
          raise "Don't know how to transform from #{val.class} to Party"
        end
    self.save!
  end
end
