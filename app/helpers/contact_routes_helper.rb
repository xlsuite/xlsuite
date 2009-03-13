#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module ContactRoutesHelper
  def contact_route_tag(contact_route, options={}, &block)
    html_options = options.reverse_merge(:id => dom_id(contact_route), :class => "row")
    if contact_route.new_record? && !options[:show_editor] then
      html_options[:style] = "display:none;"
    end

    content_tag(:div, html_options, &block)
  end
end
