#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class SnippetDrop < Liquid::Drop
  attr_reader :snippet
  delegate :id, :title, :body, :domain_patterns, :to => :snippet
  
  def initialize(snippet)
    @snippet = snippet
  end
  
  def split_body
    self.snippet.body.split(",")
  end
  
  def json_body
    self.snippet.body.to_json
  end
  
  def split_domain_patterns
    self.domain_patterns.split(/[,\n]/).reject(&:blank?).map(&:strip)

  end
end
