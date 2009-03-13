#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PageDrop < Liquid::Drop
  attr_reader :page
  delegate :updated_at, :uuid, :to => :page

  def initialize(page)
    @page = page
  end

  def title
    
    page.render_title(@context)
  end

  def body
    page.render_body(@context)
  end

  def url
    page.to_url
  end

  def author
    page.creator.name.to_s
  end
  
  def meta_description
    body = "<meta content='#{self.page.meta_description}' name='description'/>"
    
    template = Liquid::Template.parse(body)
    template.render(context)
  end
  
  def meta_keywords
    body = "<meta content='#{self.page.meta_keywords}' name='keywords'/>"
    
    template = Liquid::Template.parse(body)
    template.render(context)
  end
  
  def raw_meta_description
    template = Liquid::Template.parse(self.page.meta_description)
    template.render(context)
  end
  
  def raw_meta_keywords
    template = Liquid::Template.parse(self.page.meta_keywords)
    template.render(context)
  end
end
