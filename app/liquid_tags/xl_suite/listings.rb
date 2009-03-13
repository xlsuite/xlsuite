#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class Listings < Liquid::Block
    DefaultOptions = {:limit => "20"}.freeze
    QuotedFragment = Liquid::QuotedFragment.freeze
    TaggedAllSyntax = /tagged_all:\s*(#{QuotedFragment})/i.freeze
    TaggedAnySyntax = /tagged_any:\s*(#{QuotedFragment})/i.freeze
    LimitSyntax = /limit:\s*(\d+)/i.freeze

    def initialize(tag_name, markup, tokens)
      super

      @options = DefaultOptions.dup
      @options[:tagged_all] = $1 if markup =~ TaggedAllSyntax
      @options[:tagged_any] = $1 if markup =~ TaggedAnySyntax
      @options[:limit] = $1.to_i if markup =~ LimitSyntax

      if @options[:tagged_any].blank? && @options[:tagged_all].blank? then
        raise SyntaxError, "Expected either tagged_any or tagged_all, none found"
      elsif !@options[:tagged_any].blank? && !@options[:tagged_all].blank? then
        raise SyntaxError, "Expected either tagged_any or tagged_all, not both"
      end
    end

    def render(context)
      @listings = Listing.find_tagged_with(
          :all => context[@options[:tagged_all]],
          :any => context[@options[:tagged_any]],
          :limit => context[@options[:limit]],
          :order => "updated_at DESC")
      returning([]) do |result|
        if @listings.empty? then
          # Do nothing, as we might hit an 'ifnone' tag later on, in which case
          # we'll be able to render the proper block.
        else
          context.stack do
            context["listings"] = @listings
            result << render_all(@nodelist, context)
          end
        end
      end
    end
  end
end
