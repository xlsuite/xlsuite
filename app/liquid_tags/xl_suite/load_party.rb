#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadParty < Liquid::Tag
    CodeSyntax = /code:\s*(#{Liquid::VariableSignature}+)/
    UuidSyntax = /uuid:\s*(#{Liquid::VariableSignature}+)/
    InSyntax = /in:\s*(\w+)/

    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      @options[:code] = $1 if markup =~ CodeSyntax
      @options[:uuid] = $1 if markup =~ UuidSyntax
      @options[:in] = $1 if markup =~ InSyntax
      
      raise SyntaxError, "Can only specify uuid or code option" if @options[:code] && @options[:uuid]
      raise SyntaxError, "Missing code: or uuid: parameter in #{markup.inspect}" unless @options[:code] || @options[:uuid]
      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]
    end

    def render(context)
      current_account = context.current_account
      party = if @options[:code]
          current_account.parties.find_by_confirmation_token(context[@options[:code]])
        elsif @options[:uuid]
          current_account.parties.find_by_uuid(context[@options[:uuid]])
        else
          nil
        end

      context.scopes.last[@options[:in]] = party.to_liquid
      return ""
    end
  end
end
