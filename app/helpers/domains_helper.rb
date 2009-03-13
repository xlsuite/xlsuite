#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module DomainsHelper
  def render_domain_subscription_products_selection(domain_subscription_products_map)
    out = []
    out << "<div>"
    out << "<div>Pack selection: </div>"
    out << select_tag("level", self.render_domain_subscription_products_selection_option(domain_subscription_products_map))
    out << "</div>"
    out.join("")
  end
  
  def render_domain_subscription_products_selection_option(domain_subscription_products_map)
    option_values = []
    domain_subscription_products_map.each do |e|
      description = e[:product].name + " (" + e[:product].retail_price.to_s + ") - " + e[:number_of_domains].to_s + " pack"
      value = e[:level]
      option_values << [description, value]
    end
    options_for_select(option_values)
  end
end
