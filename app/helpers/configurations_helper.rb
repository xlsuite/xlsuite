#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module ConfigurationsHelper
  def render_configuration_value_field(configuration)
    case configuration
    when BooleanConfiguration
      %Q`
        new Ext.form.Checkbox({
          fieldLabel: "Value",
          labelSeparator: ":",
          checked: #{@configuration.value.to_json},
          name: "configuration[value]",
          inputValue: 1
        })
      `
    else
      if configuration.name =~ /auto_approve_flagging/i
        %Q`
          new Ext.form.ComboBox({
            name: "configuration[value]",
            hiddenName: "configuration[value]",
            displayField: 'display',
            valueField: 'value',
            fieldLabel: "Value",
            triggerAction: 'all',
            mode: 'local',
            allowBlank: false,
            forceSelection: true,
            editable: false,
            store: new Ext.data.SimpleStore({
              fields: ['display', 'value'],
              data: [['Always approved', 'always'], ['Logged In', 'logged_in'], ['Off', 'off']]
            }),
            value: #{current_domain.get_config("auto_approve_flagging").to_json}
          })
        `
      else
        %Q`
          new Ext.form.TextField({
            fieldLabel: "Value",
            width: 500,
            labelSeparator: ":",
            name: "configuration[value]",
            value: #{@configuration.value.to_json}
          })
        `
      end
    end
  end

  def render_form_panel_items
    configuration = @old_configuration || @configuration
    notice_id = "new_configuration"
    unless @configuration.new_record?
      notice_id = dom_id(@configuration)
    end
    %Q`
      {html: '<div class="notices" id="#{notice_id}_errorMessages"/>'},
      new Ext.form.Hidden({
        name: "id",
        value: #{configuration.id.to_json}
      }),
      new Ext.form.TextField({
        fieldLabel: "Group Name",
        labelSeparator: ":",
        width: 150,
        name: "configuration[group_name]",
        value: #{@configuration.group_name.to_json},
        disabled: true
      }),
      new Ext.form.TextField({
        fieldLabel: "Name",
        labelSeparator: ":",
        name: "configuration[name]",
        width: 150,
        value: #{@configuration.name.to_json},
        disabled: true
      }),
      new Ext.form.TextArea({
        fieldLabel: "Description",
        labelSeparator: ":",
        width: 500,
        name: "configuration[description]",
        value: #{@configuration.description.to_json},
        disabled: true
      }),
      new Ext.form.TextArea({
        fieldLabel: "Domain Patterns",
        labelSeparator: ":",
        width: 500,
        name: "configuration[domain_patterns]",
        value: #{@configuration.domain_patterns.to_json}
      }),
      #{self.render_configuration_value_field(@configuration)}
    `
  end
end
