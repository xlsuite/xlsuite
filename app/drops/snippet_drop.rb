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
end
