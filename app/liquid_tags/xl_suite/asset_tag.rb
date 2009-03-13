#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "action_view/helpers/number_helper"
require "white_list_helper"
require "erb"

module XlSuite
  class AssetTag < Liquid::Tag
    include WhiteListHelper
    include ActionView::Helpers::NumberHelper
    include ERB::Util

    DefaultOptions = {:size => "full"}.freeze
    NamedSyntax = /filename:\s*(?:['"])?(.+?)(?:['"])?(?:\s|$)/i.freeze
    SizeSyntax = /size:\s*(?:['"])?(square|mini|small|medium|large|full)(?:['"])?\b/i.freeze

    def initialize(tag_name, markup, tokens)
      super

      @options = DefaultOptions.dup
      markup.gsub!(/&quot;/i,'"')
      markup.gsub!("&#8221;", '"')
      match = NamedSyntax.match(markup)
      @options[:filename] = match[1] if match
      @options[:size] = $1 if markup =~ SizeSyntax

      raise SyntaxError, "Expected filename: option to be set" if @options[:filename].blank?
    end

    def render(context)
      asset = Asset.find_by_filename(@options[:filename])
      RAILS_DEFAULT_LOGGER.warn {"==> No asset goes by the filename #{@options[:filename].inspect}"}
      white_list(render_asset(asset, context)) unless asset.blank?
    end

    def render_asset
      raise SubclassResponsibility
    end
  end
end
