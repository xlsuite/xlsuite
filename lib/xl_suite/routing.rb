#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  module Routing
    class RouteNotFound < RuntimeError; end

    class << self
      # Given a request URI and the return value of #build, returns a Hash containing
      # the pages and bound parameters.
      #
      # == Examples
      #
      #  /blog/2008/08/13/241/building-a-better-route-builder
      #  #=> {:pages => 102, :params => {:year => "2008", :month => "08", :day => "13", :id => "241", :permalink => "building-a-better-route-builder"}}
      def recognize(uri, routes)
        logger.debug {"==> #{routes.size} route(s) to examine"}
        routes.each_pair do |regexp, options|
          logger.debug {"==> #{regexp.inspect}"}
          match = regexp.match(uri)
          logger.debug {"==> match: #{match.inspect}"}
          next unless match

          params = Hash.new
          options[:params].each_with_index do |segment, index|
            params[segment] = match[index + 1]
          end if options.has_key?(:params)

          return {:pages => options[:pages], :params => params}
        end

        # Return nil to signify we could not recognize the route
        nil
      end

      def recognize!(uri, routes)
        returning(recognize(uri, routes)) do |hash|
          raise RouteNotFound, "Could not recognize route #{uri.inspect}." if hash.nil?
        end
      end

      # Builds a Hash of {regexp => page_ids}.  Accepts a Hash of {fullslug => page_ids}.
      def build(inputs)
        returning(Hash.new) do |routes|
          inputs.each_pair do |fullslug, params|
            case params
            when Hash
              page_ids = params.delete(:pages)
            else
              page_ids = params
              params = Hash.new
            end

            case fullslug
            when /:/
              options = dynamic_route(fullslug, params)
              routes[options.delete(:regexp)] = options.merge(:pages => [page_ids].flatten)
            else
              options = static_route(fullslug)
              routes[options.delete(:regexp)] = options.merge(:pages => [page_ids].flatten)
            end
          end
        end
      end

      def static_route(fullslug)
        fullslug = normalize_fullslug(fullslug)
        {:regexp => Regexp.new("\\A#{Regexp.escape(fullslug)}\\Z", "i")}
      end

      def dynamic_route(fullslug, options)
        options[:requirements] = {} unless options.has_key?(:requirements)

        regexp, params = ["\\A"], []
        fullslug = normalize_fullslug(fullslug)
        fullslug.split("/").each do |part|
          if part[0,1] == ":" then
            # Dynamic segment
            segment_name = part[1..-1].to_sym
            segment_regexp = case segment_option = options[:requirements][segment_name]
                             when :digits, :id
                              "([\\d]+)"
                             when :year
                               "([1-9][\\d]{3})"
                             when :month
                               "(0[1-9]|1[012]|[1-9])"
                             when :day
                               "(0[1-9]|[12]\\d|3[01]|[1-9])"
                             when :permalink, NilClass
                              "([^/]+)"
                             else
                               raise ArgumentError, "Unknown segment option: #{segment_option}"
                             end

            regexp << segment_regexp
            params << segment_name
          else
            # Static segment
            regexp << Regexp.escape(part)
          end
        end
        regexp = regexp.reject(&:blank?).join("/") << "\\Z"

        {:regexp => Regexp.new(regexp, "i"), :params => params}
      end

      protected
      # Ensures a fullslug / URI is prefixed with a forward-slash.
      def normalize_fullslug(fullslug)
        fullslug[0] == ?/ ? fullslug : "/#{fullslug}"
      end

      # Gives access to the rails default logger.
      def logger
        @logger ||= RAILS_DEFAULT_LOGGER
      end
    end
  end
end
