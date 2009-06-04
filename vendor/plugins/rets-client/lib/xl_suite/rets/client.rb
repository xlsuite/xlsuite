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
        puts("^^^In transaction RETS-UA-Authorization #{client.get_header("RETS-UA-Authorization")}")      
        puts("^^^Before logging in")  
        client.login(@options[:username], @options[:password]) do
          puts("^^^Before yield")
          yield(XlSuite::Rets::RetsClient.new(client)) if block_given?
          puts("^^^After yield")
        end
      end

      def new_client
        puts("^^^At the beginning of new_client")
        returning(RETS4R::Client.new(@login_url)) do |client|
          puts("^^^Inside the do end block of new_client")
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
            puts("^^^In new_client RETS-UA-Authorization #{client.get_header("RETS-UA-Authorization")}")        
          end
          puts("^^^At the end of new_client")
        end
      end
    end
  end
end
