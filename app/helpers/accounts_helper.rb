#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module AccountsHelper
  def render_domain_thumbnail(domain, browse_link=true)
    assets = domain.find_thumbnails
    return nil if assets.blank?
    asset = assets.first

    port = request.env["SERVER_PORT"]
    host_and_port = domain.name.dup
    host_and_port << ":#{port}" unless port.blank?
    asset_url = download_asset_url(:id => asset.id, :size => "mini", :host => host_and_port)
    link_to_picture = link_to(content_tag(:img, "", :src => asset_url, :width => asset.geometry(:mini).split("x").first, :height => asset.geometry(:mini).split("x").last), "http://#{domain.name}/", :target => "_blank")
    link_to_browse = browse_link ? link_to("Click to browse", "http://#{domain.name}/", :target => "_blank", :class => "link") : ""
    content_tag(:div, link_to_picture + link_to_browse)
  end

  def account_name(account)
    name = if account.owner then
      account.owner.display_name
    elsif account.domain_name then
      account.domain_name
    else
      ""
    end

    name = "unknown" if name.blank?
    name
  end
  
  def account_template_category_selections(label)
    master_acct = Account.find_by_master(true)
    cat = master_acct.categories.find_by_label(label)
    return [] unless cat
    cat.children.all(:order => "name ASC").map {|c| [c.name, c.label]}
  end
end
