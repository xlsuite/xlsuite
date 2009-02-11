require "active_support"
require "rets4r"
require "xl_suite/rets/rets_client"

module XlSuite
  module Rets
    class Client
      def initialize(login_url, options={})
        @login_url, @options = login_url, options
      end

      def transaction
        client = self.new_client
        client.login(@options[:username], @options[:password]) do
          yield(XlSuite::Rets::RetsClient.new(client)) if block_given?
        end
      end

      def new_client
        returning(RETS4R::Client.new(@login_url)) do |client|
          client.user_agent = @options[:user_agent] unless @options[:user_agent].blank?
          client.logger = @options[:logger] unless @options[:logger].blank?
          client.rets_version = "1.7"
          client.set_pre_request_block do |rets, http, headers|
            a1 = Digest::MD5.hexdigest([headers["User-Agent"], @options[:password]].join(":"))
            if headers.has_key?("Cookie") then
              cookie = headers["Cookie"].split(";").map(&:strip).select {|c| c =~ /rets-session-id/i}
              cookie = cookie ? cookie.split("=").last : ""
            else
              cookie = ""
            end

            parts = [a1, "", cookie, headers["RETS-Version"]]
            headers["RETS-UA-Authorization"] = "Digest " + Digest::MD5.hexdigest(parts.join(":"))
          end
        end
      end
    end
  end
end
