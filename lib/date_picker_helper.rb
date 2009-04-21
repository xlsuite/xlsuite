#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

# Helper module to integrate with the JavaScript DatePicker.
# See http://opensvn.csie.org/traccgi/datepicker/trac.cgi/wiki for the
# project's home page.
module DatePickerHelper
  DefaultOptions = {:auto_field => true, :dateFormat => 'yyyy/mm/dd', :dateSeparator => '-'}

  # See #date_picker_field_tag for more information on the options to use.
  def date_picker_field(object, method, options={})
    options = DefaultOptions.dup.merge(options)
    obj = instance_eval("@#{object}")
    value = obj.send(method)
    out = hidden_field(object, method)
    out += date_picker_field_tag("#{object}_#{method}", value, :auto_field => false)
    if obj.respond_to?(:errors) and obj.errors.on(method) then
      ActionView::Base.field_error_proc.call(out, nil) # What should I pass ?
    else
      out
    end
  end

  # +options+ are:
  # [<tt>:dateFormat</tt>]: The date format.  Use only y, m, d and the slash (/)
  #  characters.
  # [<tt>:dateSeparator</tt>]: The separator to use.  Any string can be used.
  # [<tt>:auto_field</tt>]: If true, a hidden field will be created to hold the
  #  selected date.
  def date_picker_field_tag(name, value, options={})
    options = DefaultOptions.dup.merge(options)
    display_value = value.respond_to?(:strftime) ? value.strftime('%d %b %Y') : value.to_s
    display_value = '[ choose date ]' if display_value.blank?

    out = ''
    out += hidden_field_tag(name, value) if options.delete(:auto_field)
    out += link_to_function(display_value, "DatePicker.toggleDatePicker('#{name}', #{x_options_for_javascript(options)}); return false;", :id => "_#{name}_link", :class => '_demo_link')
    out += content_tag('div', '', :class => 'date_picker', :style => 'display: none',
                      :id => "_#{name}_calendar")
    out
  end

  def x_options_for_javascript(options)
    '{' + options.map {|k, v| "#{k}:'#{v}'"}.sort.join(', ') + '}'
  end
end
