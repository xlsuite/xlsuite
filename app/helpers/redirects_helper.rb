#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module RedirectsHelper
  def generate_form_panel
  out = %Q`  
    var statusStore = new Ext.data.SimpleStore({
      fields: ['value'],
      data: #{Redirect::STATUSES_FOR_SELECT.to_json}
    });

    var redirectTypeStore = new Ext.data.SimpleStore({
      fields: ['http_status', 'http_code'],
      data: #{Redirect::TYPES_FOR_SELECT.to_json}
    })
        
    var mainPanel = new Ext.Panel({
      width: '100%',
      items: [
        {
          html: '<div class="notices" id="#{dom_id(@redirect)}_errorMessages"/>'
        },
        {
          defaults: {
            // applied to each contained panel
            bodyStyle:'padding-right:20px'
          },
          items: [
            {
              layout: 'form',
              labelWidth: 60,
              items: [
                xl.widget.FormField({ value: #{@redirect.fullslug.to_json}, name: 'redirect[fullslug]', fieldLabel: 'From', id: #{(typed_dom_id(@redirect, :fullslug)).to_json}, width: 270}), 
                xl.widget.FormField({ value: #{@redirect.target.to_json}, name: 'redirect[target]', fieldLabel: 'To', id: #{(typed_dom_id(@redirect, :target)).to_json}, width: 270}), 
                {
                  html: '<p class="help">Use /target to stay in the same domain, or enter an absolute URL such as http://newdomain.com/target.</p>'
                },
                xl.widget.FormField({
                  displayField: 'http_status',
                  valueField: 'http_code',
                  hiddenName: 'redirect[http_code]',
                  type: 'combobox',
                  store: redirectTypeStore,
                  editable: false,
                  triggerAction: 'all',
                  mode: 'local',
                  fieldLabel: "Redirection type",
                  value: #{@redirect.http_code.to_json}
                }),
                xl.widget.FormField({ 
                  displayField: 'value', 
                  valueField: 'value',
                  fieldLabel: 'Status',
                  name: 'redirect[status]', 
                  type: 'combobox', 
                  store: statusStore, 
                  editable : false,
                  triggerAction: 'all',
                  mode: 'local',
                  value: #{@redirect.status.to_json}
                })
              ]
            }, 
            {
              layout: 'form', 
              items: [
                xl.widget.FormField({ type: 'textarea', value: #{@redirect.domain_patterns.to_json}, name: 'redirect[domain_patterns]', fieldLabel: 'Domain Patterns', id: #{(typed_dom_id(@redirect, :domain_pattern)).to_json}, width: 270}),
                {
                  html: '<p class="tip"><a href="http://wiki.xlsuite.org/index.php?title=Multi-domain_management" title="xlsuite wiki : multi-domain management">&uArr;What&rsquo;s this?</a><span class="italic" font-size="10px">(Separate patterns with a comma or a new line)</span></p>'
                }
              ]
            }
          ]
        }
      ]
    });
  
    var formPanel = new Ext.FormPanel({
      autoScroll: true,
      tbar: tbarbbarButtons,
      bbar: tbarbbarButtons,
      items: [mainPanel],
      trackResetOnLoad: true
    });
  `
  end

  def render_best_children_of(redirect, domain)
    matches = best_matches_for(domain, redirect.children)
    matches.blank? ? nil : render(:partial => matches)
  end

  def best_matches_for(domain, redirects)
    return redirects if domain.blank?
    redirects.group_by(&:fullslug).values.map do |rs|
      rs.best_match_for_domain(domain)
    end
  end
end
