#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module TestimonialsHelper
  def initialize_author_auto_complete_field
    if current_user.can?(:edit_testimonials)
    %Q`
      // set up connection and data store of autocomplete field
      var partyNameAutoCompleteRecord = new Ext.data.Record.create([
        {name: 'display', mapping: 'display'},
        {name: 'name', mapping: 'value'},
        {name: 'id', mapping: 'id'}
      ]);

      var partyNameAutoCompleteReader = new Ext.data.JsonReader({totalProperty: "total", root: "collection", id: "id"}, partyNameAutoCompleteRecord)
      var partyNameAutoCompleteConnection = new Ext.data.Connection({url: #{formatted_auto_complete_party_field_listings_path(:format => :json).to_json}, method: 'get'});
      var partyNameAutoCompleteProxy = new Ext.data.HttpProxy(partyNameAutoCompleteConnection)
      var partyNameAutoCompleteStore = new Ext.data.Store({proxy: partyNameAutoCompleteProxy, reader: partyNameAutoCompleteReader});
      
      var authorPartyRecord = new partyNameAutoCompleteRecord({
        display: #{self.party_auto_complete_display(current_user).to_json},
        id: #{current_user.id.to_json}
      });
      partyNameAutoCompleteStore.add([authorPartyRecord]);

      var authorAutoCompleteField = new Ext.form.ComboBox({
        store: partyNameAutoCompleteStore,
        displayField: 'display',
        valueField: 'id',
        hiddenName: "testimonial[author_id]",
        fieldLabel: "Author",
        triggerAction: 'all',
        forceSelection: true,
        minChars: 0,
        width: 480,
        allowBlank: false,
        value: #{self.party_auto_complete_display(current_user).to_json},
        listeners: {
            "change": function(comboBox, newValue, oldValue){
              var partyName = partyNameAutoCompleteStore.getById(newValue).get("name");
              authorNameField.setValue(partyName);
            },
            render: function(cpt){
              cpt.hiddenField.setValue(#{current_user.id.to_json});
            }
          }
      });
    `
    else
    %Q`
      var authorAutoCompleteTextField = new Ext.form.TextField({
        disabled: true,
        fieldLabel: "Author",
        width: 480,
        value: #{self.party_auto_complete_display(current_user).to_json}
      });
      
      var authorHiddenField = new Ext.form.Hidden({
        name: "testimonial[author_id]",
        value: #{current_user.id.to_json}
      });
      
      var authorAutoCompleteField = new Ext.Panel({
        layout: "form",
        items: [authorAutoCompleteTextField, authorHiddenField]
      });
    `
    end
  end
  
  def initialize_edit_author_auto_complete_field
    %Q`
      // set up connection and data store of autocomplete field
      var partyNameAutoCompleteRecord = new Ext.data.Record.create([
        {name: 'display', mapping: 'display'},
        {name: 'id', mapping: 'id'}
      ]);

      var partyNameAutoCompleteReader = new Ext.data.JsonReader({totalProperty: "total", root: "collection", id: "id"}, partyNameAutoCompleteRecord)
      var partyNameAutoCompleteConnection = new Ext.data.Connection({url: #{formatted_auto_complete_party_field_listings_path(:format => :json).to_json}, method: 'get'});
      var partyNameAutoCompleteProxy = new Ext.data.HttpProxy(partyNameAutoCompleteConnection)
      var partyNameAutoCompleteStore = new Ext.data.Store({proxy: partyNameAutoCompleteProxy, reader: partyNameAutoCompleteReader});

      var authorPartyRecord = new partyNameAutoCompleteRecord({
        display: #{(@testimonial.author.nil? ? "" : self.party_auto_complete_display(@testimonial.author)).to_json},
        id: #{(@testimonial.author.nil? ? "" : @testimonial.author.id).to_json}
      });
      partyNameAutoCompleteStore.add([authorPartyRecord]);

      var authorAutoCompleteField = new Ext.form.ComboBox({
        store: partyNameAutoCompleteStore,
        displayField: 'display',
        valueField: 'id',
        hiddenName: "testimonial[author_id]",
        fieldLabel: "Author",
        triggerAction: 'all',
        forceSelection: true,
        minChars: 0,
        width: 480,
        value: #{(@testimonial.author.nil? ? "" : self.party_auto_complete_display(@testimonial.author)).to_json},
        disabled: #{current_user.can?(:edit_testimonials) ? "false" : "true"},
        listeners: {
          render: function(cpt){
            cpt.hiddenField.setValue(#{(@testimonial.author.nil? ? "" : @testimonial.author.id).to_json});
          }
        }
      });
    `
  end
end
