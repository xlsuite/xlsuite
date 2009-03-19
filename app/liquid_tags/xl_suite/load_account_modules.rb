#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadAccountModules < Liquid::Tag
    OrderSyntax = /order:\s*(#{Liquid::QuotedFragment})/
    InSyntax = /in:\s*(#{Liquid::QuotedFragment})/

    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      @options[:order] = $1 if markup =~ OrderSyntax
      @options[:in] = $1 if markup =~ InSyntax

      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]
    end

    def render(context)
      context_options = Hash.new
      
      [:order].each do |option_sym|
        context_options[option_sym] = context[@options[option_sym]]
        context_options[option_sym] = @options[option_sym] unless context_options[option_sym]
      end
      
      if !@options[:order]
        context_options[:order] = "module ASC"
      else
        temp = nil
        accepted_ordering = []
        context_options[:order].split(",").map(&:strip).each do |o|
          temp = o.gsub(/\s+/, " ").split(" ")
          if temp.first =~ /^(name|module)$/i
            temp[0] = "module"
          elsif temp.first =~ /^(fee|minimum_subscription_fee|minimum_subscription_fee_cents)$/i
            temp[0] = "minimum_subscription_fee_cents"
          end
          if temp.size > 1
            temp = temp[0] + " " + temp[1]
          else
            temp = temp[0]
          end
          accepted_ordering << temp
        end
        if accepted_ordering.empty?
          context_options[:order] = "module ASC"
        else
          context_options[:order] = accepted_ordering.join(",")
        end
      end
      
      account_modules = AccountModule.all(:order => context_options[:order])
      
      context[@options[:in]] = account_modules.map(&:to_liquid)
      nil
    end
  end
end
