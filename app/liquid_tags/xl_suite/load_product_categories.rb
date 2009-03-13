#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadProductCategories < Liquid::Tag
    InSyntax = /in:\s*(\w+)/
    NamesSyntax = /names:\s*(#{Liquid::QuotedFragment})/
    LabelsSyntax = /labels:\s*(#{Liquid::QuotedFragment})/
    PrivateSyntax = /private:\s*(#{Liquid::QuotedFragment})/
    PublicSyntax = /public:\s*(#{Liquid::QuotedFragment})/
    ChildOnlySyntax = /child_only:\s*(#{Liquid::QuotedFragment})/
    RootOnlySyntax = /root_only:\s*(#{Liquid::QuotedFragment})/

    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      @options[:in] = $1 if markup =~ InSyntax
      @options[:names] = $1 if markup =~ NamesSyntax
      @options[:labels] = $1 if markup =~ LabelsSyntax
      @options[:private] = $1 if markup =~ PrivateSyntax
      @options[:public] = $1 if markup =~ PublicSyntax
      @options[:child_only] = $1 if markup =~ ChildOnlySyntax
      @options[:root_only] = $1 if markup =~ RootOnlySyntax

      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]
    end

    def render(context)
      returning "" do
        options = Hash.new
        context_options = Hash.new
        conditions = []

        current_account = context.current_account
        
        [:names, :labels].each do |option_sym|
          context_options[option_sym] = context[@options[option_sym]]
          context_options[option_sym] = @options[option_sym] unless context_options[option_sym]
        end
        
        ids = []
        if @options[:names]
          names = context_options[:names].split(",").map(&:strip)
          ids += current_account.product_categories.all(:select => "id", :conditions => {:name => names}).map(&:id)
        end

        if @options[:labels]
          labels = context_options[:labels].split(",").map(&:strip)
          ids += current_account.product_categories.all(:select => "id", :conditions => {:label => labels}).map(&:id)
        end

        ids.uniq!
        conditions << "product_categories.id IN (#{ids.join(',')})" unless ids.empty?
        
        if @options[:private]
          conditions << "product_categories.private = 1"
        elsif @options[:public]
          conditions << "product_categories.private = 0"
        end
        
        if @options[:child_only]
          conditions << "product_categories.parent_id IS NOT NULL"
        elsif @options[:root_only]
          conditions << "product_categories.parent_id IS NULL"
        end
        
        product_categories = current_account.product_categories.find(:all, :conditions => conditions)
        
        context[@options[:in]] = product_categories
      end
    end
  end
end
