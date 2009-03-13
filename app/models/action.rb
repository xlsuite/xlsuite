#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Action
  AVAILABLE_ACTIONS = Dir[File.join(RAILS_ROOT, "app", "actions", "*")].map do |file| 
    File.basename(file, ".rb").classify
  end
  
  def initialize(params={})
    params.each_pair do |key, value|
      self.send("#{key}=", value)
    end
  end
  
  def description
    ""
  end
end
