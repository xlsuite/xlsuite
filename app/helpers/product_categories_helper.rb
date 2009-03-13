#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module ProductCategoriesHelper
  def render_header_links
    out = ""
    out << link_to_function("Product Manager", "xl.openNewTabPanel('products_index_nil', #{products_path.to_json})")
    out << link_to_function("New Product", "xl.openNewTabPanel('products_new_nil', #{new_product_path.to_json})")
    out.to_json
  end
  
  def render_header_options
    out = ""
    out.to_json
  end
  
  def render_img_tag_or_none(id)
    if id.nil?
      return "<div style=\"height: 140px; width: 140px; background-color: #EEE;\">&nbsp;</div>"
    else
      return "<img src=\"#{download_asset_path(:id => id)}?size=small\" height=\"140\" />"
    end
  end
end
