$:.unshift File.join(File.dirname(__FILE__), "../..", "lib")

require 'test/unit'
require 'rets4r/client/parser/xmlparser'
require 'test/client/test_parser'

module RETS4R
	class Client
		if Module.constants.include?('XMLParser') && SUPPORTED_PARSERS.include?(Parser::XMLParser)
			class TestCParser < Test::Unit::TestCase
				include TestParser
				
				def setup
					@parser = Parser::XMLParser.new
				end
			end
		else
			puts "Skipping RETS4R XMLParser testing because XMLParser is not available."
		end
	end
end