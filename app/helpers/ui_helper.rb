#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module UiHelper
  def render_record_mappings(columns)
    out = []
    columns.each do |column|
      out << "{name: '#{column[:name]}', mapping: '#{column[:name]}'}"
    end
    out.join(",")
  end
  
  def render_grid_column_model(columns)
    out = []
    columns.each do |column|
      next unless column[:display]
      out <<  "{header: '#{column[:human_name]}', width: 100, sortable: true, dataIndex: '#{column[:name]}', hidden: #{!column[:display]}}"
    end
    out.join(",")
  end
end
