#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module ImportsHelper

  def display_csv_lines(rows)
    return "DO NOT PERFORM IMPORT ON THIS FILE! Wrong file format: please save as a .CSV file and ensure that UTF-8 is enabled." if rows == -1
    html = []
    html << '<table id="importDataTable">'
    unless rows.blank?
      row_column_size = rows.first.size
      row_size = rows.size
      for i in 0..row_column_size-1
        html << "<tr>"
        for j in 0..row_size-1
          html << "<td>#{rows[j][i]}</td>"
        end
        html << "</tr>"
      end    
    end
    html << "</table>"
    return html
  end

  def render_import_errors(import)
    html = []
    errors = import.import_errors.reverse
    row_idx = import.mappings ? import.mappings[:header_lines_count] : 0
    row_idx = row_idx.to_i
    for e in import.imported_lines
      row_idx += 1
      next if e
      error = errors.pop
      html << "<tr>"
      html << "<td>#{row_idx}</td>"
      html << "<td>#{error[0].inspect}</td>"
      html << "<td>#{error[1].to_s}</td>"
      html << "</tr>"
    end
    return html
  end
end
