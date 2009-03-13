#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class LabellingFormBuilder < ActionView::Helpers::FormBuilder
  def text_field(method, options={})
    @template.content_tag(:p, %Q(#{label(method, options)}#{super}))
  end

  def view_field(*args)
    case
    when 1 == args.length
      if args.first.kind_of?(Hash) then
        args.unshift(nil)
      else
        args.push(Hash.new)
      end
    when 0 == args.length || args.length > 2
      raise "Need 1 or 2 arguments for #view_field"
    end

    method, options = *args
    value = options.delete(:value) || @object.send(method)
    @template.content_tag(:p, %Q(#{label(method, options)} <span class="view">#{value}</span>))
  end

  def password_field(method, options={})
    @template.content_tag(:p, %Q(#{label(method, options)}#{super}))
  end

  def text_area(method, options={})
    @template.content_tag(:p, %Q(#{label(method, options)}#{super}))
  end

  def file_field(method, options={})
    @template.content_tag(:p, %Q(#{label(method, options)}#{super}))
  end

  def select(method, choices, options={})
    @template.content_tag(:p, %Q(#{label(method, options)}#{super}))
  end

  def datetime_select(method, options={})
    @template.content_tag(:p, %Q(#{label(method, options)}#{super}))
  end

  def collection_select(method, choices, id, text, options={})
    @template.content_tag(:p, %Q(#{label(method, options)}#{super}))
  end

  def check_box(method, options={})
    text = label_text(method, options)
    @template.content_tag(:p, %Q(<label class="checkbox#{' required' if options.delete(:required)}">#{super} #{text}</label>))
  end

  def radio_button(method, options={})
    text = label_text(method, options)
    @template.content_tag(:p, %Q(<label class="radio#{' required' if options.delete(:required)}">#{super} #{text}</label>))
  end

  def file_column_field(method, options={})
    @template.content_tag(:p, "#{self.file_field(method, options)}#{self.hidden_field(method.to_s + '_temp', {:skip_label => true}.merge(options))}")
  end

  def text_area_with_auto_complete(method, options={})
    returning("") do |editor|
      editor << self.text_area(method, options)
      editor << "\n"

      indicator_id = @template.typed_dom_id(self.object, method, :indicator)
      field_id = "#{self.object_name}_#{method}"
      with = options[:with]
      auto_complete_id = @template.typed_dom_id(self.object, method, :auto_complete)

      editor << @template.throbber(indicator_id)
      editor << @template.content_tag(:div, "",
          :id => auto_complete_id,
          :class => "auto_complete", :style => "display:none")

      auto_completer = if options[:url] then
        @template.javascript_tag <<EOF
var #{@template.typed_dom_id(self.object, method, :auto_completer)} = new Ajax.Autocompleter(
  '#{field_id}',
  '#{auto_complete_id}',
  '#{options[:url]}',
  {
    method: "get", paramName: "q", parameters: "#{with}",
    indicator: "#{indicator_id}", tokens: [',', '\\n', ' ']
  }
);
EOF
      elsif options[:values] then
        @template.javascript_tag <<EOF
var #{@template.typed_dom_id(self.object, method, :auto_completer)} = new Autocompleter.Local(
  '#{field_id}',
  '#{auto_complete_id}',
  #{options[:values].to_json},
  {
    ignoreCase: true, partialChars: 1, frequency: 0.1
  }
);
EOF
      else
        raise ArgumentError, "Either :url or :values is expected to generate an auto completer.  None found in #{options.inspect}"
      end

      editor << auto_completer
    end
  end

  protected
  def label(method, options)
    text = label_text(method, options)
    required = options.delete(:required)
    return nil if options.delete(:skip_label)

    name = object_name.to_s.gsub('[]', '')
    name << "_#{options[:index]}" if options[:index]

    %Q(<label for="#{name}_#{method}"#{' class="required"' if required}>#{text}:</label>)
  end

  def label_text(method, options)
    options.delete(:label) || method.to_s.humanize.titleize
  end
end
