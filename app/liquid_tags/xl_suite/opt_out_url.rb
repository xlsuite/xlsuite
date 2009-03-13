#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class OptOutUrl < Liquid::Tag
    DefaultOptions = {:domain => ""}.freeze 
    DomainSyntax = /domain:\s*(['"])(.*?)\1/i.freeze

    def initialize(tag_name, markup, tokens)
      super

      @options = DefaultOptions.dup
      markup.gsub!(/&quot;/i,'"')
      markup.gsub!("&#8221;", '"')

      @options[:domain] = $2.strip.downcase if markup =~ DomainSyntax
    end

    def render(context)
      account = context.current_account
      recipient = context.recipient
      domain_name = @options[:domain].blank? ? recipient.domain_name : @options[:domain]

      "http://#{domain_name}#{recipient.email.opt_out_url}?id=#{recipient.uuid}"
    end
  end
end
