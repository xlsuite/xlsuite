#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class DomainDrop < Liquid::Drop
  delegate :name, :to => :domain
  attr_reader :domain

  def initialize(domain=nil)
    @domain = domain
  end
  
  def url
    "http://#{self.domain.name}"
  end
  
  def before_method(method)
    if method.to_s =~ /^get_config_(.*)/i
      return self.domain.get_config($1)
    end
    if method.to_s =~ /^get_id_of_config_(.*)/i
      return Configuration.retrieve($1, self.domain).id
    end
    nil
  end
end
