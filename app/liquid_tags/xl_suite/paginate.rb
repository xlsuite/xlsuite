#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class Paginate < Liquid::Block
    PerPageSyntax = /per_page:\s*(#{Liquid::QuotedFragment})/
    TotalCountSyntax = /total_count:\s*(#{Liquid::QuotedFragment})/
    PageSyntax = /\bpage:\s*(#{Liquid::QuotedFragment})/

    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      @options[:per_page] = $1 if markup =~ PerPageSyntax
      @options[:total_count] = $1 if markup =~ TotalCountSyntax
      @options[:page] = $1 if markup =~ PageSyntax
      

      specifications = [@options[:total_count], @options[:page]].flatten.compact
      raise SyntaxError, "Please specify both page: and total_count:" if specifications.size < 2
    end

    def render(context)
      
      result = []
      context_options = Hash.new
      
      [:per_page, :total_count, :page].each do |option_sym|
        context_options[option_sym] = context[@options[option_sym]].to_i
        context_options[option_sym] = @options[option_sym].to_i unless context_options[option_sym]
      end
      
      context_options[:per_page] = context_options[:per_page] <= 0 ? 10 : context_options[:per_page]
      
      first_entry_index = ((context_options[:page]-1) * context_options[:per_page]) + 1
      last_entry_index = (context_options[:page] * context_options[:per_page])
      last_entry_index = context_options[:total_count] if(last_entry_index > context_options[:total_count])
      
      pages_count = (context_options[:total_count].to_f / context_options[:per_page].to_f).ceil
      
      next_page = context_options[:page] + 1 if (context_options[:page] ) < pages_count
      previous = context_options[:page] - 1 if (context_options[:page] - 1) > 0
      
      context.stack do
      	context['page'] = {
      		'first_entry_index1' => first_entry_index,
      		'last_entry_index1' => last_entry_index,
      		'first_entry_index0' => first_entry_index - 1,
      		'last_entry_index0' => last_entry_index - 1,
      		'next' => next_page,
      		'previous' => previous,
      		'entries' => last_entry_index - first_entry_index + 1,
      		'number' => context_options[:page],
      		'total_count' => context_options[:total_count],
          'total_pages' => pages_count
      	}
      	result << render_all(@nodelist, context)
      end
      
      result
      
    end
  end
end
