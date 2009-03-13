#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module SaleEventsHelper
  def sale_event_tag_after_update
    return nil if @sale_event.new_record?
    %Q`
      function() {
        var params = {};
        params["sale_event[tag_list]"] = $F("#{typed_dom_id(@sale_event, :tag_list, :field)}");
        Element.show("#{typed_dom_id(@sale_event, :tag_list, :indicator)}");
        new Ajax.Request("#{sale_event_path(@sale_event)}", {
          method: 'put',
          onComplete: function() { Element.hide("#{typed_dom_id(@sale_event, :tag_list, :indicator)}"); },
          submit: "#{dom_id(@sale_event)}_display_info", parameters: params
        });
      }
    `
  end
  
  def sale_event_checkbox_js(method_name)
    return nil if @sale_event.new_record?
    %Q`
      var check = "0";
      if (this.checked) {
        check = "1";
      }
      var params = {};
      params["sale_event[#{method_name}]"] = check;
        Element.show("#{typed_dom_id(@sale_event, method_name.to_sym, :indicator)}");
        new Ajax.Request("#{sale_event_path(@sale_event)}", {
          method: 'put',
          onComplete: function() { Element.hide("#{typed_dom_id(@sale_event, method_name.to_sym, :indicator)}"); },
          parameters: params
        });
    `
  end
  
  def render_starts_at_and_ends_at
    out = %Q`
      var startsAtDateField = new Ext.form.DateField({
        name: 'sale_event[starts_at]',
        format: 'm/d/Y',
        allowBlank: false,
        width: 100,
        value: #{to_extjs_date_field_value(@sale_event.starts_at).to_json},
        renderTo: #{typed_dom_id(@sale_event, :starts_at_date_field).to_json}
      });
    
      var endsAtDateField = new Ext.form.DateField({
        name: 'sale_event[ends_at]',
        format: 'm/d/Y',
        allowBlank: false,
        width: 100,
        value: #{to_extjs_date_field_value(@sale_event.ends_at).to_json},
        renderTo: #{typed_dom_id(@sale_event, :ends_at_date_field).to_json}
      });
    `
    return out if @sale_event.new_record?
    out << %Q`
      startsAtDateField.on('change', function(dateField, newValue, oldValue){
        var params = {};
        params["sale_event[starts_at]"] = dateField.value;
        Element.show("#{typed_dom_id(@sale_event, :starts_at, :indicator)}");
        new Ajax.Request("#{sale_event_path(@sale_event)}", {
          method: 'put',
          onComplete: function() { Element.hide("#{typed_dom_id(@sale_event, :starts_at, :indicator)}"); },
          parameters: params
        });
      });

      endsAtDateField.on('change', function(dateField, newValue, oldValue){
        var params = {};
        params["sale_event[ends_at]"] = dateField.value;
        Element.show("#{typed_dom_id(@sale_event, :ends_at, :indicator)}");
        new Ajax.Request("#{sale_event_path(@sale_event)}", {
          method: 'put',
          onComplete: function() { Element.hide("#{typed_dom_id(@sale_event, :ends_at, :indicator)}"); },
          parameters: params
        });
      });
    `
    out
  end  
end
