#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module EntitiesHelper
  def entity_tag_after_update
    return nil if @entity.new_record?
    %Q`
      function() {
        var params = {};
        params["entity[tag_list]"] = $F("#{typed_dom_id(@entity, :tag_list, :field)}");
        Element.show("#{typed_dom_id(@entity, :tag_list, :indicator)}");
        new Ajax.Request("#{entity_path(@entity)}", {
          method: 'put',
          onComplete: function() { Element.hide("#{typed_dom_id(@entity, :tag_list, :indicator)}"); },
          submit: "#{dom_id(@entity)}_display_info", parameters: params
        });
      }
    `
  end
end
