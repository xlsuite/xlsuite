#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module SuppliersHelper
  def supplier_tag_after_update
    return nil if @supplier.new_record?
    %Q`
      function() {
        var params = {};
        params["supplier[tag_list]"] = $F("#{typed_dom_id(@supplier, :tag_list, :field)}");
        Element.show("#{typed_dom_id(@supplier, :tag_list, :indicator)}");
        new Ajax.Request("#{supplier_path(@supplier)}", {
          method: 'put',
          onComplete: function() { Element.hide("#{typed_dom_id(@supplier, :tag_list, :indicator)}"); },
          submit: "#{dom_id(@supplier)}_display_info", parameters: params
        });
      }
    `
  end
end
