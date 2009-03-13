#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module DomainPatternsSplitter
  def patterns
    self.domain_patterns.split(/,|\n/).map(&:strip).reject(&:blank?)
  end
end
