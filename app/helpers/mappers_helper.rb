#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module MappersHelper
  include ImportsHelper
  
  TransformationOptions = ["As-is", "Lowercase", "Stripped", "Titleize", "Uppercase"].freeze
  DefaultTransformationOption = "As-is"
  
  def render_mapping_table_header(size=0)
    html = []
    html << "<th class='mappingsTableIndexColumn'>Column</th>"
    for i in 1..size
      html << "<th>Data Row #{i}</th>" 
    end
    html << "<th>Store In</th>"
    if size == 0
      html << "<th class='mappingsTableTransformColumn' colspan='2'>Transform</th>"
    else
      html << "<th class='mappingsTableTransformColumn'>Transform</th>"
    end
    html << "<th class='mappingsTableAvailableColumn'>Available Mapping Columns</th>"
    return html
  end
  
  def render_mapper_rows(data_rows=nil, mappings=nil)
    if mappings
      mappings = mappings.clone
      mappings = mappings[:map]
    end
    mappings = [{}, {}, {}, {}, {}] if mappings.blank?

    html = []
    num_of_mapping_rows = mappings.size
    if !data_rows.blank?
      num_of_mapping_rows = data_rows[0].size
    end
    html << hidden_field_tag("num_of_mapping_rows", num_of_mapping_rows)
    for i in 0..(num_of_mapping_rows-1)
      html << %Q{<tr class="#{cycle("odd", "")}">}
      html << content_tag(:td, i+1, :class => 'mappingIndex')
      if data_rows
        for data in data_rows
          html << content_tag(:td, data[i])
        end
      end
      html << content_tag(:td, content_tag(:span, "", :class => "mapping"), :class => "mapping")
      html << hidden_field_tag("mappings[map][#{i+1}][model]", get_mapping_model(mappings[i])) 
      html << hidden_field_tag("mappings[map][#{i+1}][field]", get_mapping_field(mappings[i])) 
      html << hidden_field_tag("mappings[map][#{i+1}][name]", get_mapping_name(mappings[i])) 
      html << content_tag(:td, 
          select_tag("mappings[map][#{i+1}][tr]", 
              options_for_select(TransformationOptions, get_mapping_tr(mappings[i]) || DefaultTransformationOption)
          ) 
      )
      if data_rows.blank?
        html << content_tag(:td, link_to_function("Clear", "clearThisMappingRow(this)"))
      end
      if i==0
        html << content_tag(:td, render(:partial => "mappers/available_mapping_columns"), :rowspan => num_of_mapping_rows)
      else
        html << content_tag(:td)
      end
      html << "</tr>"
    end
    return html
  end
  
protected
  def get_mapping_model(hash)
    return "" if hash.blank?
    return "" if !hash.has_key?(:model)
    hash[:model]
  end
  
  def get_mapping_field(hash)
    return "" if hash.blank?
    return "" if !hash.has_key?(:field)
    hash[:field]
  end

  def get_mapping_name(hash)
    return "" if hash.blank?
    return "" if !hash.has_key?(:name)
    hash[:name]
  end
  
  def get_mapping_tr(hash)
    return "" if hash.blank?
    return "" if !hash.has_key?(:tr)
    hash[:tr]
  end

  def get_mapping_value(hash)
    return "" if hash.blank?
    return "" if !hash.has_key?(:model) || !hash.has_key?(:field)
    text = []
    text << hash[:model]
    text << hash[:field]
    text << hash[:name]
    return text.compact.join("||")
  end
  
  def get_mapping_display(hash)
    return "" if hash.blank?
    return "" if !hash.has_key?(:model) || !hash.has_key?(:field)
    text = []
    text << if hash[:field] == "url" then "URL" 
      elsif hash[:field] == "email_address" then "E-Mail"
      else hash[:field].titleize
      end
    text << "(#{hash[:name].titleize})" if hash.has_key?(:name) && !hash[:name].blank?
    return text.join(" ")
  end
end
