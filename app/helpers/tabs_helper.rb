#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module TabsHelper
  def tab(name, url, li_options={})
    if url == request.env['REQUEST_URI'] then
      li_options[:id] = "current"
      li_options[:class] ||=""
      li_options[:class] += " selected"
      li_options[:class].strip!
    end

    content_tag(:li, link_to(name, url), li_options)
  end
end
