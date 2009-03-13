#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PdfGenerator
  def initialize(invoice)
    @invoice = invoice
  end

  def build(options={})
    options[:site] ||= 'wpul'

    @owner = Configuration.get(:owner, options[:site])
    pdf = PDF::Writer.new(:paper => 'LETTER', :version => '1.3', :orientation => :portrait)
    pdf.margins_in(1.5, 0.5, 0.5, 0.75)
    pdf.select_font 'Times-Roman'
    File.open(File.join(RAILS_ROOT, 'public', 'images', "#{options[:site]}-logo.jpg"), 'rb') do |logo|
      pdf.open_object do |header|
        pdf.save_state
        pdf.add_image_from_file logo, pdf.in2pts(0.5), pdf.in2pts(10), pdf.in2pts(3)
        pdf.add_text pdf.in2pts(0.5), pdf.in2pts(9.85),
            "#{@owner.main_address.format.join(', ')} - Phone: #{@owner.main_phone.number}",
            10

        text = "#{options[:type].to_s.capitalize} No: #{@invoice.number}"
        font_size = 10
        text_width = pdf.text_width(text, font_size)
        pdf.add_text pdf.in2pts(8.5) - pdf.in2pts(0.5) - text_width, pdf.in2pts(9.85),
            text, font_size

        pdf.move_to pdf.in2pts(0.5), pdf.in2pts(10) - 16
        pdf.line_to pdf.in2pts(8.5) - pdf.in2pts(0.5), pdf.in2pts(10) - 16
        pdf.stroke

        pdf.restore_state
        pdf.close_object

        pdf.add_object(header, :all_pages)
      end

      pdf.open_object do |footer|
        pdf.save_state

        font_size = 10
        if @owner then
          text = "#{@owner.company_name} - #{@owner.main_address.format.join(', ')} - Phone: #{@owner.main_phone.number}"
        else
          text = "NO CUSTOMER !!!"
        end
        text_size = pdf.text_width(text, font_size)
        pdf.add_text pdf.margin_x_middle - text_size/2.0, pdf.in2pts(0.5), text, font_size

        pdf.move_to pdf.in2pts(0.5), pdf.in2pts(0.5) + 16
        pdf.line_to pdf.in2pts(8.5) - pdf.in2pts(0.5), pdf.in2pts(0.5) + 16
        pdf.stroke

        pdf.restore_state
        pdf.close_object

        pdf.add_object(footer, :all_pages)
      end

      pdf.start_columns(2, pdf.in2pts(0.5))

      pdf.text "Sold To:"
      if @invoice.customer then
        pdf.text "<b>#{@invoice.customer.company_name}</b>" unless @invoice.customer.company_name.blank?
        pdf.text "<b>#{@invoice.customer.name}</b>"
        pdf.text(@invoice.customer.main_address.format) if @invoice.customer.main_address
        pdf.text "\nPhone: #{@invoice.customer.main_phone.number}" \
            unless  @invoice.customer.main_phone.blank? || \
                    @invoice.customer.main_phone.number.blank?
      else
        pdf.text "<b>No Customer</b>"
      end

      pdf.start_new_page  # Starts a new column, instead

      pdf.text "Date: #{(@invoice.date || Time.now).to_time.strftime('%d/%m/%Y')}", :justification => :right
      pdf.text "#{options[:type].to_s.capitalize} No: #{@invoice.number}", :justification => :right
      pdf.text "Our GST #: #{Configuration.get(:company_gst_number)}", :justification => :right
      pdf.text "Our PST #: #{Configuration.get(:company_pst_number)}", :justification => :right

      pdf.stop_columns

      if :quote == options[:type] then
        pdf.text "\nThis is an estimate - the final amount billed will be based upon the number of strands of lights and ancillary products actually used to complete the work.",
            :font_size => 12, :justification => :center, :left => pdf.in2pts(0.5), :right => pdf.in2pts(0.5)
      end

      pdf.text "\n"
      PDF::SimpleTable.new do |table|
        table.width = pdf.in2pts(8.5 - 1.25)
        table.position = :center
        table.bold_headings = true
        table.minimum_space = 50
        table.protect_rows = 2

        table.column_order = %w(description product_no unit_price quantity extension_price)
        table.columns['description'] = PDF::SimpleTable::Column.new('description') {|col| col.heading = 'Description' }
        table.columns['product_no'] = PDF::SimpleTable::Column.new('product_no') {|col| col.heading = 'Product No' }
        table.columns['unit_price'] = PDF::SimpleTable::Column.new('unit_price') {|col| col.heading = 'Unit Price'; col.justification = :right }
        table.columns['quantity'] = PDF::SimpleTable::Column.new('quantity') {|col| col.heading = 'Quantity'; col.justification = :right }
        table.columns['extension_price'] = PDF::SimpleTable::Column.new('extension_price') {|col| col.heading = 'Extension'; col.justification = :right }
        data = @invoice.lines.map do |item|
          row = {'description' => item.description}

          case
          when item.product?
            row.merge!( 'product_no' => item.no,
                        'unit_price' => item.unit_price.format(:html),
                        'quantity' => item.quantity,
                        'extension_price' => item.extension_price.format(:html),
                        'description' => "   #{row['description']}")

          when item.manhours?
            row.merge!( 'unit_price' => item.unit_price.format(:html),
                        'quantity' => item.quantity,
                        'extension_price' => item.extension_price.format(:html),
                        'description' => "   #{row['description']}")

          when item.comment?
            row['description'] = "<b>#{row['description']}</b>"
          end

          row
        end

        data << {'quantity' => 'Subtotal:', 'extension_price' => @invoice.subtotal}
        data << {'quantity' => 'Equipment Fee:', 'extension_price' => @invoice.equipment_fee} unless @invoice.equipment_fee.zero?
        data << {'quantity' => 'Transportation:', 'extension_price' => @invoice.transport_fee} unless @invoice.transport_fee.zero?
        data << {'quantity' => 'Shipping Fee:', 'extension_price' => @invoice.shipping_fee} unless @invoice.shipping_fee.zero?
        data << {'quantity' => "#{@invoice.fst_name} (#{@invoice.fst_subtotal} x #{@invoice.fst_rate / 1000}%):", 'extension_price' => @invoice.fst_amount} if @invoice.fst?
        data << {'quantity' => "#{@invoice.pst_name} (#{@invoice.pst_subtotal} x #{@invoice.pst_rate / 1000}%):", 'extension_price' => @invoice.pst_amount} if @invoice.pst?
        data << {'quantity' => "Total:", 'extension_price' => @invoice.total.format(:with_currency)}
        data << {'quantity' => "<b>Balance due</b>:", 'extension_price' => @invoice.balance.format(:with_currency)} unless @invoice.balance.zero?

        table.data = data
        table.render_on(pdf)
      end

      unless @invoice.payments.empty? then
        pdf.text "\n<b>Payment History</b>", :font_size => 14
        pdf.text "", :font_size => 8
        PDF::SimpleTable.new do |table|
          table.width = pdf.in2pts(8.5 - 1.25)
          table.position = :center
          table.bold_headings = true
          table.minimum_space = 50
          table.protect_rows = 2

          table.column_order = %w(date method reason status amount)
          table.columns['date'] = PDF::SimpleTable::Column.new('date') {|col| col.heading = 'Date'; col.justification = :right }
          table.columns['method'] = PDF::SimpleTable::Column.new('method') {|col| col.heading = 'Method' }
          table.columns['reason'] = PDF::SimpleTable::Column.new('reason') {|col| col.heading = 'Reason' }
          table.columns['status'] = PDF::SimpleTable::Column.new('status') {|col| col.heading = 'Status' }
          table.columns['amount'] = PDF::SimpleTable::Column.new('amount') {|col| col.heading = 'Amount'; col.justification = :right }

          table.data = @invoice.payments.map do |payment|
            { 'date' => payment.updated_at.to_time.strftime('%d/%m/%Y %H:%M'),
              'method' => payment.method_name,
              'reason' => payment.reason,
              'status' => payment.status,
              'amount' => payment.amount.format(:with_currency)}
          end

          table.render_on(pdf)
        end
      end

      unless @invoice.notes.blank? then
        pdf.text "\n<b>Notes</b>", :font_size => 14
        pdf.text @invoice.notes, :font_size => 11
      end

      upcoming_jobs = @invoice.upcoming_jobs(@invoice.created_at)
      unless upcoming_jobs.empty? then
        pdf.text "\n<b>Upcoming jobs</b>", :font_size => 14
        pdf.text 'We have the following jobs scheduled with you:', :font_size => 11

        upcoming_jobs.each do |job|
          text = "* #{job.job_date.to_time.strftime('%d/%m/%Y %H:%M')}"
          text << " (#{job.duration} hours)" if job.duration != 0
          text << " - #{job.description}"
          pdf.text text, :font_size => 11, :left => pdf.in2pts(0.25)
        end
      end

      return pdf.render
    end
  end
end
