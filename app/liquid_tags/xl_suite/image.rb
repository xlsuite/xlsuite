#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class Image < XlSuite::AssetTag
    def render_asset(asset, context)
      asset = asset.find_or_initialize_thumbnail(@options[:size]) unless @options[:size] == "full"
      <<-EOF
<img src="/assets/download/#{url_encode(asset.filename)}" alt="#{html_escape(asset.title)}" width="#{asset.width}" height="#{asset.height}"/>
      EOF
    end
  end
end
