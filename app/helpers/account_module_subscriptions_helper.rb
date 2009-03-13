#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module AccountModuleSubscriptionsHelper
  def initialize_module_selections
    %Q`
    
    `
  end
  
  def initialize_installed_account_modules_panel
    modules = @acct_mod_subscription.installed_account_modules.map(&:humanize)
    content = ""
    if modules.empty?
      content = "No module to be installed by this subscription"
    else
      content = "<ul>"
      modules.each do |mod_name|
        content << ("<li>" + mod_name + "</li>")
      end
      content << "</ul>"
    end
    %Q`
      var installedAccountModulesPanel = new Ext.Panel({
        title: "Modules",
        html: #{content.to_json}
      })
    `
  end
end
