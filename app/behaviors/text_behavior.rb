#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class TextBehavior < Behavior
  def serialize(params)
    self.page.body = params[:text]
  end

  def deserialize
    {:text => self.page.body}
  end

  def render(context)
    template = template_for(self.text)
    template.render!(context)
  end

  def text
    self.page.body
  end
end
