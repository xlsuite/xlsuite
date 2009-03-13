#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module OverlibHelper
  DefaultContentStyles = 'position:absolute; visibility:hidden; z-index:1000;'.freeze

  def overlib_popup(link_text, long_text, url_options={})
    return h(link_text) if long_text.blank?
    options = url_options.empty? ? 'javascript:void(0);' : url_options
    link_to(link_text, options,
            :onmouseover => "return overlib('#{escape_javascript(sanitize(long_text))}');",
            :onmouseout => 'return nd();')
  end

  def overlib_sticky(link_text, long_text, url_options={})
    return h(link_text) if long_text.blank?
    options = url_options.empty? ? 'javascript:void(0);' : url_options
    link_to(link_text, options,
            :onmouseover => "return overlib('#{escape_javascript(sanitize(long_text))}', STICKY, MOUSEOFF);",
            :onmouseout => 'return nd();')
  end

  def overlib_content(dom_id='overDiv', styles=DefaultContentStyles)
    content_tag('div', '', :id => dom_id, :style => styles)
  end
end
