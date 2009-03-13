#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module AssetsHelper
  def with_thumbnail(asset, size, &block)
    size = size.to_s
    thumb = asset.thumbnails.find_by_thumbnail(size)
    if thumb then
      url = download_asset_path(:id => asset, :size => size)
    else
      thumb = asset
      url = download_asset_path(asset)
    end

    concat(capture(thumb, url, &block), block.binding)
  end

  def link_to_size(asset)
    if asset.thumbnail.blank? then
      url = download_asset_url(asset)
    else
      url = download_asset_url(:id => asset, :size => asset.thumbnail)
    end

    buffer = []
    buffer << %Q(<li>)
    buffer << %Q(<a href="#{url}">)
    buffer << content_tag(:span, asset.geometry.sub("x", "&times;"), :class => "geometry")
    buffer << content_tag(:span, asset.thumbnail.blank? ? "Full Size" : asset.thumbnail.titleize, :class => "name")
    buffer << %Q(</a>)
    buffer << %Q(</li>)
    buffer.join("\n")
  end

  def download_links(asset)
    buffer = []
    root = asset.parent ? asset.parent : asset
    root.thumbnails.map {|t| [t.geometry.split("x").first.to_i, t]}.sort_by {|e| e[0]}.map(&:last).each do |thumbnail|
      buffer << link_to_size(thumbnail)
    end
    buffer << link_to_size(root)

    buffer.join("\n")
  end

  def icon_for(asset)
    :page_white
  end
end
