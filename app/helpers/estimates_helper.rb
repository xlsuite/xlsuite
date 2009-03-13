#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module EstimatesHelper
  def update_shipping_msg
    "$('#{typed_dom_id(@estimate, :recommended_shipping)}').innerHTML = '#{@recommend_msg}';"
  end
  
  def update_invoice_to
    "$('#{typed_dom_id(@estimate, :invoice_to)}').innerHTML = '#{@estimate.invoice_to.display_name}';"
  end
  
  def update_taxes
    out = %Q`
      $('#{typed_dom_id(@estimate, :fst_name_field)}').value = '#{@estimate.fst_name}';
      $('#{typed_dom_id(@estimate, :fst_name_show)}').innerHTML = '#{@estimate.fst_name}';
      $('#{typed_dom_id(@estimate, :pst_name_field)}').value = '#{@estimate.pst_name}';
      $('#{typed_dom_id(@estimate, :pst_name_show)}').innerHTML = '#{@estimate.pst_name}';
    `
    out
  end
  
  def update_totals
    out = %Q`
      $('#{typed_dom_id(@estimate, :subtotal)}').innerHTML = '#{@estimate.subtotal_amount.to_s}';
      $('#{typed_dom_id(@estimate, :total)}').innerHTML = '#{@estimate.total_amount.to_s}';
    `
    out << "$('#{typed_dom_id(@estimate, :subtotal)}').highlight();" if @old_subtotal != @estimate.subtotal_amount
    out << "$('#{typed_dom_id(@estimate, :total)}').highlight();" if @old_total != @estimate.total_amount
    
  end
  
  def update_ship_to
    out = %Q`
      $('#{typed_dom_id(@estimate, :line1)}').value = '#{@estimate.ship_to.line1}';
      $('#{typed_dom_id(@estimate, :line2)}').value = '#{@estimate.ship_to.line2}';
      $('#{typed_dom_id(@estimate, :line3)}').value = '#{@estimate.ship_to.line3}';
      $('#{typed_dom_id(@estimate, :city)}').value = '#{@estimate.ship_to.city}';
      $('#{typed_dom_id(@estimate, :state)}').value = '#{@estimate.ship_to.state}';
      $('#{typed_dom_id(@estimate, :country)}').value = '#{@estimate.ship_to.country}';
      $('#{typed_dom_id(@estimate, :zip)}').value = '#{@estimate.ship_to.zip}';
    `
    out
  end
  
  def renderTextFieldEditor
    %Q`
      new Ext.form.TextField({
        allowBlank: false, 
        listeners: { 
          'focus': { 
            fn: function(me){
              me.selectText();
            }
          } 
        }
      })
    `
  end
  
  def estimate_status_selections
    "['All'],['Cancelled'],['Completed'],['Fulfilled'],['Unfulfilled']"
  end
  
  def edit_estimate_status_selections
    "['Cancelled'],['Completed'],['Fulfilled'],['Unfulfilled']"    
  end

  def generateTotalMessage
    %Q`
      "<table style='text-indent: 5px;'>
        <tr>
          <td></td>
          <td>Labor</td>
          <td>Products</td>
        </tr>
        <tr>
          <td>Subtotal</td>
          <td>"+response.labor_amount+"</td>
          <td>"+response.products_amount+"</td>
        </tr>
        <tr>
          <td>FST ("+response.fst_rate+"%)</td>
          <td>"+response.labor_fst_amount+"</td>
          <td>"+response.products_fst_amount+"</td>
        </tr>
        <tr>
          <td>PST ("+response.pst_rate+"%)</td>
          <td>"+response.labor_pst_amount+"</td>
          <td>"+response.products_pst_amount+"</td>
        </tr>
        <tr>
          <td>Shipping</td>
          <td colspan='2'>"+response.shipping_fee+"</td>
        </tr>
        <tr>
          <td>Equipment</td>
          <td colspan='2'>"+response.equipment_fee+"</td>
        </tr>
        <tr>
          <td>Transport</td>
          <td colspan='2'>"+response.transport_fee+"</td>
        </tr>
        <tr style='height:10pt'><td colspan=4></td></tr>
        <tr>
          <td>Grand Total</td>
          <td colspan=2><b>"+response.total_amount+"</b></td>
        </tr>
      </table>"
    `.gsub("\n", "")
  end
  
  def render_estimates_status_selection_field
    %Q`
      <select>
        <option>All</option>
        <option>Unfulfilled</option>
        <option>Fulfilled</option>
        <option>Completed</option>
        <option>Cancelled</option>
      </select>
    `
  end
  
  def estimate_checkbox_js(method_name)
    return nil if @estimate.new_record?
    %Q`
      var check = "0";
      if (this.checked) {
        check = "1";
      }
      var params = {};
      params["estimate[#{method_name}]"] = check;
        Element.show("#{typed_dom_id(@estimate, method_name.to_sym, :indicator)}");
        new Ajax.Request("#{estimate_path(@estimate)}", {
          method: 'put',
          onComplete: function() { Element.hide("#{typed_dom_id(@estimate, method_name.to_sym, :indicator)}"); },
          parameters: params
        });
    `
  end
  
  def estimate_tag_after_update
    return nil if @estimate.new_record?
    %Q`
      function() {
        var params = {};
        params["estimate[tag_list]"] = $F("#{typed_dom_id(@estimate, :tag_list, :field)}");
        Element.show("#{typed_dom_id(@estimate, :tag_list, :indicator)}");
        new Ajax.Request("#{estimate_path(@estimate)}", {
          method: 'put',
          onComplete: function() { Element.hide("#{typed_dom_id(@estimate, :tag_list, :indicator)}"); },
          submit: "#{dom_id(@estimate)}_display_info", parameters: params
        });
      }
    `
  end
  
  def create_DateField
    out = %Q`
      var DateField = new Ext.form.DateField({
        name: 'estimate[date]',
        format: 'm/d/Y',
        width: 100, 
        fieldLabel: "Date"`
    if @estimate.date
      out << ",value: #{to_extjs_date_field_value(@estimate.date.to_time).to_json}" 
    elsif @estimate.new_record?
      out << ",value: #{to_extjs_date_field_value(Time.now).to_json}" 
    end
    out << "});"
    return out if @estimate.new_record?
    out << %Q`
      DateField.on('change', function(dateField, newValue, oldValue){
        var params = {};
        params["estimate[date]"] = dateField.value;
        new Ajax.Request("#{estimate_path(@estimate)}", {
          method: 'put',
          parameters: params
        });
      });
    `
    out
  end
  
  def create_InvoiceToButton
    
    partyNameComboBox = %Q!
  new Ext.form.ComboBox({
    store: partyNameAutoCompleteStore,
    displayField: 'display',
    valueField: 'id',
    cls: "add_party_to_listing_combo_box",
    hideLabel: true,
    triggerAction: 'all',
    forceSelection: true,
    minChars: 0,
    width: 480,
    allowBlank: false
  });
!
    out = %Q`
      
      
      
  // set up connection and data store of autocomplete field
var partyNameAutoCompleteRecord = new Ext.data.Record.create([
  {name: 'display', mapping: 'display'},
  {name: 'value', mapping: 'value'},
  {name: 'id', mapping: 'id'}
]);

var partyNameAutoCompleteReader = new Ext.data.JsonReader({totalProperty: "total", root: "collection", id: "id"}, partyNameAutoCompleteRecord);
var partyNameAutoCompleteConnection = new Ext.data.Connection({url: #{formatted_auto_complete_party_field_listings_path(:format => :json).to_json}, method: 'get'});
var partyNameAutoCompleteProxy = new Ext.data.HttpProxy(partyNameAutoCompleteConnection);
var partyNameAutoCompleteStore = new Ext.data.Store({proxy: partyNameAutoCompleteProxy, reader: partyNameAutoCompleteReader});
  
var addToPartiesAction = new Ext.Action({
  text: "Choose Contact", 
  iconCls: "display_none",
  handler: function(e) {
    var comboBoxes = [];
    
    var partyNameComboBox = #{partyNameComboBox}
    
    comboBoxes.push(partyNameComboBox);
    
    var win = new Ext.Window({
      title: "Please find the party. The field will autocomplete.",
      modal: true,
      layout:'form',
      width:500,
      autoHeight:true,
      closeAction:'hide',
      plain: true,
      items: [ partyNameComboBox ],
      buttons: [{
        text:'Submit',
        ` 
      if @estimate.new_record?
        out << %Q`
        handler: function(){
          var party_ids = [];
          comboBoxes.each(function(el){ party_ids.push(el.getValue());});
          $('new_estimate_invoice_to').innerHTML = partyNameComboBox.getRawValue();
          Ext.get('new_estimate_hidden_invoice_to_id').dom.setValue(partyNameComboBox.getValue());
          Ext.get('new_estimate_hidden_invoice_to_type').dom.setValue("Party");
          win.hide();
        }`
      else
        out << %Q`
          handler: function(){
            var party_ids = [];
            comboBoxes.each(function(el){ party_ids.push(el.getValue());});
            var params = {
              'estimate[invoice_to_id]': party_ids.join(','),
              'estimate[invoice_to_type]': "Party"
            };
            Ext.Ajax.request({
              url: #{estimate_path(@estimate).to_json},
              method: "PUT",
              params: params,
              failure: xl.logXHRFailure
            }); // end Ext.Ajax.request
            win.hide();
          }`
      end
      
        out << %Q`
    },{
        text: 'Close',
        handler: function(){
            win.hide();
        }
      }]
    });
    
    win.show();
  }
  
 
});
  var HiddenInvoiceToIdField = new Ext.form.Hidden({
    id: "new_estimate_hidden_invoice_to_id",
    name: 'estimate[invoice_to_id]'
`
out << %Q`
    ,value: #{@estimate.invoice_to.id}
` if @estimate.invoice_to
out << %Q`
  });
  var HiddenInvoiceToTypeField = new Ext.form.Hidden({
    id: "new_estimate_hidden_invoice_to_type",
    name: 'estimate[invoice_to_type]'
`
out << %Q`
    ,value: #{@estimate.invoice_to.class.to_s.to_json}
` if @estimate.invoice_to
out << %Q`
  });
  var InvoiceToButton = new Ext.Button(addToPartiesAction);   `
    out
  end
end
