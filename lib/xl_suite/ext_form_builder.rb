#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class ExtFormBuilder < ActionView::Helpers::FormBuilder
    # Renders a money field.  Includes cents and currency.
    def money_field(attribute, options={})
      value = attr_value(attribute, options)
      text_field(attribute, options.merge(:value => value.to_s))
    end

    # Renders an integer value field.
    def integer_field(attribute, options={})
      value = sprintf("%d", attr_value(attribute, options))
      text_field(attribute, options.merge(:value => value))
    end

    def select(attribute, choices, options={})
      text_field(attribute, options)
    end

    # Renders a floating point value field.  The actual value will be printed
    # according to the :decimals options.
    #
    # == Examples
    #  number_field(:margin, :decimals => 2)
    def number_field(attribute, options={})
      decimals = options.delete(:decimals) || 2
      value = sprintf("%.#{decimals}f", attr_value(attribute, options))
      text_field(attribute, options.merge(:value => value))
    end

    # Renders a plain text field
    def text_field(attribute, options={})
      afteredit = options.delete(:afteredit)
      field_options = options.reverse_merge(:type => "text", :value => object.send(attribute),
        :name => attribute.to_s, :fieldLabel => label(attribute, options))
      JsonLiteral.new("xl.widget.InlineActiveField({form: form, #{('afteredit: '+afteredit+',') unless afteredit.blank?} field: #{field_options.to_json}})")
    end

    # Renders a textarea
    def text_area(attribute, options={})
      afteredit = options.delete(:afteredit)
      label = options.delete(:label) || attribute.to_s.titleize
      field_options = options.reverse_merge(:type => "textarea", :value => object.send(attribute),
        :name => attribute.to_s, :fieldLabel => label(attribute, options))
      JsonLiteral.new("xl.widget.InlineActiveField({form: form, #{('afteredit: '+afteredit+',') unless afteredit.blank?} field: #{field_options.to_json}})")
    end

    # Instantiates an ExtJS Ext.Panel.  Defaults are:
    #  {width: "100%", autoScroll: true}
    def panel(options={})
      options.reverse_merge!(:width => "100%", :auto_scroll => true)
      yield(options[:items] = Items.new) if block_given?

      javascriptify_keys!(options)
      JsonLiteral.new("new Ext.Panel(#{options.to_json})")
    end

    # Instantiates an ExtJS Ext.TabPanel.  Defaults are:
    #  {tabPosition: "bottom", border: false, bodyBorder: false, frame: false}
    def tab_panel(options={})
      options.reverse_merge!(:tab_position => :bottom, :border => false, :body_border => false, :frame => false)
      yield(options[:items] = Items.new) if block_given?

      javascriptify_keys!(options)
      JsonLiteral.new("new Ext.TabPanel(#{options.to_json})")
    end

    # Instantiates an ExtJS Ext.DataView.  Defaults are:
    #  {autoHeight: true, frame: false, layout: "fit"}
    def data_view(options={})
      options.reverse_merge!(:auto_height => true, :frame => false, :layout => :fit)
      javascriptify_keys!(options)
      JsonLiteral.new("new Ext.DataView(#{options.to_json})")
    end

    def xtemplate(template)
      JsonLiteral.new("new Ext.XTemplate(#{template.to_json})")
    end

    protected
    def attr_value(attribute, options)
      options[:value] || object.send(attribute)
    end

    def javascriptify_keys!(object)
      returning(object) do
        case object
        when Hash
          object.keys.each do |key|
            value = object.delete(key)
            jskey = key.to_s.camelize
            jskey[0] = jskey[0,1].downcase
            object[jskey] = value

            javascriptify_keys!(value)
          end

        when Array
          object.collect! {|item| javascriptify_keys!(item) }
        end
      end
    end

    def label(attribute, options)
      options.delete(:label) || attribute.to_s.titleize
    end
  end

  class Items < Array
    def add(options={})
      returning(self) do
        yield(options[:items] = Items.new) if block_given?
        self << options
      end
    end
  end
end
