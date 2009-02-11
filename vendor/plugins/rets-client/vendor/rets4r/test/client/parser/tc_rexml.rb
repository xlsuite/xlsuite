$:.unshift File.join(File.dirname(__FILE__), "../..", "lib")

require 'test/unit'
require 'rets4r/client/parser/rexml'
require 'test/client/test_parser'

module RETS4R
	class Client		
		class TestRParser < Test::Unit::TestCase
			include TestParser
			
			def setup
				@parser = Parser::REXML.new
			end
		end
	end
end