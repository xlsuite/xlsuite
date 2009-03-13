#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class DownloadLink < XlSuite::AssetTag
    def render_asset(asset, context)
      <<-EOF
<a href="/assets/download/#{url_encode(asset.filename)}"><span class="icon"><img src="/images/icons/#{asset.icon}.png" alt=""/></span> #{html_escape(asset.filename)} <span class="size">#{number_to_human_size(asset.size)}</span></a>
      EOF
    end
  end
end
