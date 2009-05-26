#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module CommentsHelper
  def render_form_panel_items
    %Q`
      {
        layout: "form", 
        items: [
          {html: '<div class="notices" id="#{dom_id(@comment)}_errorMessages"/>'},
          new Ext.form.TextField({
            fieldLabel: "Name",
            labelSeparator: ":",
            grow: true,
            growMin: 150,
            name: "comment[name]",
            value: #{@comment.name.to_json}
          }),
          new Ext.form.TextField({
            fieldLabel: "Email",
            labelSeparator: ":",
            grow: true,
            growMin: 150,
            name: "comment[email]",
            value: #{@comment.email.to_json}
          }),
          new Ext.form.ComboBox({
            name: "",
            hiddenName: "comment[rating]",
            displayField: 'display',
            valueField: 'value',
            fieldLabel: 'Rating',
            triggerAction: 'all',
            mode: 'local',
            allowBlank: false,
            forceSelection: true,
            store: new Ext.data.SimpleStore({
              fields: ['display', 'value'],
              data: [['None', null], ["1", 1], ["2", 2], ["3", 3], ["4", 4], ["5", 5]]            
            }),
            value: #{@comment.rating.to_json}   
          }),
          new Ext.form.TextField({
            fieldLabel: "URL",
            labelSeparator: ":",
            grow: true,
            growMin: 150,
            name: "comment[url]",
            value: #{@comment.url.to_json}
          }),
          new Ext.form.Checkbox({
            fieldLabel: "Approved",
            name: "approved",
            checked: #{!@comment.approved_at.nil?}
          }),
          {html: "Body/Content"},
          new Ext.form.TextArea({
            hideLabel: true,
            name: 'comment[body]',
            width: '99%',
            height: 350,
            value: #{@comment.body.to_json},
            listeners: {
              'resize': function(component){
                var size = component.ownerCt.body.getSize();
                component.suspendEvents();
                component.setSize(size.width-20, 350);
                component.resumeEvents();
              }
            }, 
            style: "font-family:monospace"
          })
        ]
      }
    `
  end
end
