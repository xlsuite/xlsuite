#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class InlineFormBuilder < ActionView::Helpers::FormBuilder
    def hidden_field(method, options={})
      super(method, options.merge(:id => @template.typed_dom_id(self.object, method, :field)))
    end

    def view_field(method, options={})
      make_indexed!(options)
      html_options = normalize_options(method, options)

      editor = @template.content_tag(:span, options[:value] || self.object.send(method), html_options)
      wrap_inline(method, editor, options)
    end

    def text_field_with_inline_editor(method, options={})
      make_indexed!(options)
      html_options = normalize_options(method, options)

      editor = text_field_without_inline_editor(method, html_options)
      wrap_inline(method, editor, options)
    end

    alias_method_chain :text_field, :inline_editor

    def password_field(method, options={})
      make_indexed!(options)
      html_options = normalize_options(method, options)

      editor = super(method, html_options)
      wrap_inline(method, editor, options)
    end

    def text_area_with_inline_editor(method, options={})
      make_indexed!(options)
      html_options = normalize_options(method, options)
      
      editor = text_area_without_inline_editor(method, html_options)
      wrap_block(method, editor, options)
    end

    alias_method_chain :text_area, :inline_editor

    def tags_field(method, options={})
      make_indexed!(options)
      html_options = normalize_options(method, options)

      options[:value] = self.object.send(method)
      editor = text_area_without_inline_editor(method, html_options)
      options[:value] = "<em>None</em>" if options[:value].blank?
      wrap_inline(method, editor, options)
    end

    def select(method, choices, options={})
      make_indexed!(options)
      html_options = normalize_options(method, options)

      editor = super(method, choices, options, html_options)
      wrap_inline(method, editor, options)
    end

    def text_field_with_auto_complete(attribute, options={})
      make_indexed!(options)
      with = options.delete(:with)

      plain_attribute = attribute.to_s.gsub("_id", "")

      editor = []
      data_id = @template.typed_dom_id(object, attribute, :field)
      copy_id = nil
      if attribute.to_s.ends_with?("_id") then
        html_options = normalize_options(plain_attribute, options).merge(:name => "auto_complete[#{attribute}]")
        field_id = html_options[:id]
        html_options[:data_field] = data_id
        editor << self.text_field_without_inline_editor(plain_attribute, html_options)
        editor << @template.content_tag(:div,
            self.hidden_field(attribute,
                options.merge(:id => data_id, :value => object.send(attribute))),
            :style => "display:none")
        copy_id = %Q(afterUpdateElement: function(element, selected){$(element.getAttribute("data_field")).value = selected.id.split("_").last();},)
      else
        html_options = normalize_options(plain_attribute, options)
        field_id = html_options[:id]
        editor << self.text_field_without_inline_editor(plain_attribute, html_options)
      end

      auto_complete_id = @template.typed_dom_id(self.object, plain_attribute, :auto_complete)
      editor << @template.content_tag(:div, "",
          :id => auto_complete_id,
          :class => "auto_complete", :style => "display:none")

      auto_completer = if options[:url] then
        @template.javascript_tag <<EOF
var #{@template.typed_dom_id(self.object, plain_attribute, :auto_completer)} = new Ajax.Autocompleter(
  '#{field_id}',
  '#{auto_complete_id}',
  '#{options[:url]}',
  {
    method: "get", paramName: "q", parameters: "#{with}",
    tokens: ['\\n'],
    #{copy_id}
    indicator: "#{@template.typed_dom_id(self.object, plain_attribute, :indicator)}"
  }
);
EOF
      elsif options[:values] then
        @template.javascript_tag <<EOF
var #{@template.typed_dom_id(self.object, plain_attribute, :auto_completer)} = new Autocompleter.Local(
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
      wrap_inline(plain_attribute, editor.join("\n"), options)
    end

    def save_or_cancel_links(save_url, columns=[], options={})
      return if save_url.blank? && !object.new_record?

      main_id = @template.typed_dom_id(object).gsub(/_$/, "")
      loading_code = []
      loading_code << %Q(Element.show("#{@template.typed_dom_id(object, :throbber)}"))
      columns.each do |column|
        loading_code << %Q($("#{main_id}_#{column}_show").innerHTML = $F("#{main_id}_#{column}_field"))
        loading_code << %Q(Element.hide("#{main_id}_#{column}_edit"))
        loading_code << %Q(Element.show("#{main_id}_#{column}_show"))
      end

      cancel_code = []
      cancel_code << %Q(Element.remove("#{main_id}");)

      buffer = []
      buffer << @template.link_to_remote("Save", :url => save_url, :method => "post",
          :submit => main_id,
          :loading => loading_code.join("; ")) unless save_url.blank?
      buffer << @template.throbber(@template.typed_dom_id(object, :throbber))
      buffer << @template.link_to_function("Cancel", cancel_code.join("; ")) if object.new_record?

      @template.content_tag(:div, buffer.join("\n"), :class => options[:inline] ? nil : "row")
    end

    protected
    def wrap_inline(attribute, editor, options={})
      wrap(attribute, editor, options.merge(:editor_type => :inline))
    end

    def wrap_block(attribute, editor, options={})
      wrap(attribute, editor, options.merge(:editor_type => :block))
    end

    def wrap(attribute, editor, options={})
      show_element_id = @template.typed_dom_id(self.object, attribute, :show)
      edit_element_id = @template.typed_dom_id(self.object, attribute, :edit)
      value = options[:value] || self.object.send(attribute)
      value = RedCloth.new(value || "", [:filter_html, :filter_styles]).to_html(:textile) if options[:editor_type] == :block

      add_style!("display:none", options) if options[:show_editor]
      options.merge!(:row => true, :fieldset => true) if options[:wrap]
      
      show_editor = options.has_key?(:show_editor) ? options[:show_editor] : object.new_record?
      
      returning "" do |buffer|
        buffer << %Q(<div id="#{@template.typed_dom_id(self.object, attribute)}" class="row">) if options[:row]
        buffer << %Q(<fieldset>) if options[:fieldset]
        buffer << %Q(<label for="#{edit_element_id}">#{options[:label]}</label>) if options[:label]
        options[:shower] ||= <<EOF
#{@template.content_tag(:div, value,
    :id => show_element_id, :tabindex => 0,
    :class => ["show", options[:editor_type], value.blank? ? "blank" : nil].compact.join(" "),
    :style => show_editor ? "display:none" : nil)}
EOF
        buffer << options[:shower]
        buffer << <<EOF
#{@template.content_tag(:div, editor,
    :url => self.options[:url],
    :id => edit_element_id,
    :class => "edit #{options[:editor_type]}",
    :style => show_editor ? nil : "display:none")}
#{@template.throbber(@template.typed_dom_id(self.object, attribute, :indicator), :class => "inline")}
EOF
        buffer << %Q(</fieldset>) if options[:fieldset]
        buffer << %Q(</div>) if options[:row]
      end
    end

    def add_style!(style, options={})
      returning options do
        options[:style] = ((options[:style] || "").split(";") + [style]).map {|k| k.strip}.join("; ")
      end
    end

    def add_class_name!(class_name, options={})
      returning options do
        options[:class] = ((options[:class] || "") + " #{class_name}").strip
      end
    end

    def add_class_name(class_name, options={})
      returning options.dup do |opts|
        opts[:class] = ((opts[:class] || "") + " #{class_name}").strip
      end
    end

    # Adds <tt>:index</tt> to the options Hash, if this builder was
    # instantiated with the <tt>:indexed</tt> option set to true.
    def make_indexed!(options)
      options[:index] =  self.object_index if self.options[:indexed]
    end

    def object_index
      @last_used_index ||= self.object.id || Time.now.to_i + rand(1000000)
    end

    def normalize_options(method, options)
      returning options.dup do |html_options|
        html_options.reverse_merge!(:use_default_value => true)
        html_options[:class] = [html_options[:class], object.class.name.underscore, method, :subtleField].map(&:to_s).join(" ")
        html_options.delete(:row)
        html_options.delete(:fieldset)
        html_options.delete(:wrap)
        html_options.delete(:show_editor)
        html_options.delete(:values)
        html_options.delete(:url)
        html_options[:id] = @template.typed_dom_id(object, method, :field)
        if html_options.delete(:use_default_value)
          html_options.delete(:value) if html_options[:value].blank?
          html_options.reverse_merge!(:value => (object.new_record? && object.respond_to?(method) && object.send(method).blank?) ? method.to_s.humanize.titleize : object.send(method))
        end
      end
    end
  end
end
