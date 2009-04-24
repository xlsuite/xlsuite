#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module OrdersHelper
  def update_shipping_msg
    "$('#{typed_dom_id(@order, :recommended_shipping)}').innerHTML = '#{@recommend_msg}';"
  end
  
  def update_invoice_to
    "$('#{typed_dom_id(@order, :invoice_to)}').innerHTML = #{@order.invoice_to.display_name.to_json};"
  end
  
  def update_taxes
    out = %Q`
      $('#{typed_dom_id(@order, :fst_name_field)}').value = '#{@order.fst_name}';
      $('#{typed_dom_id(@order, :fst_name_show)}').innerHTML = '#{@order.fst_name}';
      $('#{typed_dom_id(@order, :pst_name_field)}').value = '#{@order.pst_name}';
      $('#{typed_dom_id(@order, :pst_name_show)}').innerHTML = '#{@order.pst_name}';
    `
    out
  end
  
  def update_totals
    out = %Q`
      $('#{typed_dom_id(@order, :subtotal)}').innerHTML = '#{@order.subtotal_amount.to_s}';
      $('#{typed_dom_id(@order, :total)}').innerHTML = '#{@order.total_amount.to_s}';
    `
    out << "$('#{typed_dom_id(@order, :subtotal)}').highlight();" if @old_subtotal != @order.subtotal_amount
    out << "$('#{typed_dom_id(@order, :total)}').highlight();" if @old_total != @order.total_amount
    
  end
  
  def update_ship_to
    out = %Q`
      $('#{typed_dom_id(@order, :line1)}').value = '#{@order.ship_to.line1}';
      $('#{typed_dom_id(@order, :line2)}').value = '#{@order.ship_to.line2}';
      $('#{typed_dom_id(@order, :line3)}').value = '#{@order.ship_to.line3}';
      $('#{typed_dom_id(@order, :city)}').value = '#{@order.ship_to.city}';
      $('#{typed_dom_id(@order, :state)}').value = '#{@order.ship_to.state}';
      $('#{typed_dom_id(@order, :country)}').value = '#{@order.ship_to.country}';
      $('#{typed_dom_id(@order, :zip)}').value = '#{@order.ship_to.zip}';
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
  
  def order_status_selections
    "['All'],['Cancelled'],['Void'],['WriteOff'],['New'],['Pending'],['Shipped'],['Completed']"
  end
  
  def edit_order_status_selections
    "['Cancelled'],['Void'],['WriteOff'],['New'],['Pending'],['Shipped'],['Completed']"    
  end

  def generateTotalMessage
    %Q`
      "<table style='text-indent: 5px;'>
        <tr>
          <td></td>
          <td>Labor</td>
          <td>Products</td>
          <td>Shipping, Equipment, and Transport Costs</td>
        </tr>
        <tr>
          <td>Subtotal</td>
          <td>"+response.labor+"</td>
          <td>"+response.products+"</td>
          <td>"+response.shipping+"</td>
        </tr>
        <tr>
          <td>FST ("+response.fst+"%)</td>
          <td>"+response.labor_fst+"</td>
          <td>"+response.products_fst+"</td>
          <td>"+response.shipping_fst+"</td>
        </tr>
        <tr>
          <td>PST ("+response.pst+"%)</td>
          <td>"+response.labor_pst+"</td>
          <td>"+response.products_pst+"</td>
          <td>"+response.shipping_pst+"</td>
        </tr>
        <tr>
          <td>Totals</td>
          <td>"+response.labor_total+"</td>
          <td>"+response.products_total+"</td>
          <td>"+response.shipping_total+"</td>
        </tr>
        <tr style='height:10pt'><td colspan=4></td></tr>
        <tr>
          <td>Grand Total</td>
          <td colspan=2><b>"+response.total+"</b></td>
        </tr>
      </table>"
    `.gsub("\n", "")
  end
  
  def render_orders_status_selection_field
    %Q`
      <select>
        <option>All</option>
        <option>New</option>
        <option>Pending</option>
        <option>Shipped</option>
        <option>Completed</option>
      </select>
    `
  end
  
  def order_checkbox_js(method_name)
    return nil if @order.new_record?
    %Q`
      var check = "0";
      if (this.checked) {
        check = "1";
      }
      var params = {};
      params["order[#{method_name}]"] = check;
        Element.show("#{typed_dom_id(@order, method_name.to_sym, :indicator)}");
        new Ajax.Request("#{order_path(@order)}", {
          method: 'put',
          onComplete: function() { Element.hide("#{typed_dom_id(@order, method_name.to_sym, :indicator)}"); },
          parameters: params
        });
    `
  end
  
  def order_tag_after_update
    return nil if @order.new_record?
    %Q`
      function() {
        var params = {};
        params["order[tag_list]"] = $F("#{typed_dom_id(@order, :tag_list, :field)}");
        Element.show("#{typed_dom_id(@order, :tag_list, :indicator)}");
        new Ajax.Request("#{order_path(@order)}", {
          method: 'put',
          onComplete: function() { Element.hide("#{typed_dom_id(@order, :tag_list, :indicator)}"); },
          submit: "#{dom_id(@order)}_display_info", parameters: params
        });
      }
    `
  end
  
  def create_DateField
    out = %Q`
      var DateField = new Ext.form.DateField({
        name: 'order[date]',
        format: 'm/d/Y',
        width: 100, 
        fieldLabel: "Date"`
    if @order.date
      out << ",value: #{to_extjs_date_field_value(@order.date.to_time).to_json}" 
    elsif @order.new_record?
      out << ",value: #{to_extjs_date_field_value(Time.now).to_json}" 
    end
    out << "});"
    return out if @order.new_record?
    out << %Q`
      DateField.on('change', function(dateField, newValue, oldValue){
        var params = {};
        params["order[date]"] = dateField.value;
        new Ajax.Request("#{order_path(@order)}", {
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
      if @order.new_record?
        out << %Q`
        handler: function(){
          var party_ids = [];
          comboBoxes.each(function(el){ party_ids.push(el.getValue());});
          $('new_order_invoice_to').innerHTML = partyNameComboBox.getRawValue();
          Ext.get('new_order_hidden_invoice_to_id').dom.setValue(partyNameComboBox.getValue());
          Ext.get('new_order_hidden_invoice_to_type').dom.setValue("Party");
          win.hide();
        }`
      else
        out << %Q`
          handler: function(){
            var party_ids = [];
            comboBoxes.each(function(el){ party_ids.push(el.getValue());});
            var params = {
              'order[invoice_to_id]': party_ids.join(','),
              'order[invoice_to_type]': "Party"
            };
            Ext.Ajax.request({
              url: #{order_path(@order).to_json},
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
    id: "new_order_hidden_invoice_to_id",
    name: 'order[invoice_to_id]'
`
out << %Q`
    ,value: #{@order.invoice_to.id}
` if @order.invoice_to
out << %Q`
  });
  var HiddenInvoiceToTypeField = new Ext.form.Hidden({
    id: "new_order_hidden_invoice_to_type",
    name: 'order[invoice_to_type]'
`
out << %Q`
    ,value: #{@order.invoice_to.class.to_s.to_json}
` if @order.invoice_to
out << %Q`
  });
  var InvoiceToButton = new Ext.Button(addToPartiesAction);   `
    out
  end
end
