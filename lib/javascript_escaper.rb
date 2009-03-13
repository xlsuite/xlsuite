#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module JavascriptEscaper
  def self.escape(string=nil)
    text = string || ""
    text.gsub!(/\\+/, "")
    text.gsub!("'","\\\\'")
    text.gsub!('"','\\\\"')
    text.gsub!("\n","\\n")
    text.gsub!("\r","\\r")
    text
  end
  
  def e(string=nil)
    JavascriptEscaper::escape(string)
  end
end

ActiveRecord::Base.send(:include, JavascriptEscaper)
ActionController::Base.send(:include, JavascriptEscaper)
ActionView::Base.send(:include, JavascriptEscaper)
