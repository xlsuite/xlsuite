$:.unshift File.join(File.dirname(__FILE__), "../..", "lib")

require 'rets4r/client/metadataindex'
require 'rets4r/client/transaction'
require 'rets4r/client/metadata'
require 'test/unit'

module RETS4R
	class TestMetadataIndex < Test::Unit::TestCase
	
	def test_truth
	end
	
=begin
		def setup
			File.open('tests/rets/data/metadata.marshal') do |file|
				@trans = Marshal.load(file)
			end

			@index = MetadataIndex.new(@trans.data)
		end
		
		# Ensure that our lookup and search functions, although different, will return the same data
		# for the same criteria.
		def test_lookup_search
			assert_equal("Club House", @index.lookup('METADATA-LOOKUP_TYPE', 'Property', 'HOAMENITIS_Lkp_2')[0]['LongValue'])
			
			puts @index.search('METADATA-LOOKUP_TYPE', {'Resource' => 'Property', 'Lookup' => 'HOAMENITIS_Lkp_2'}).inspect
			assert_equal( \
				@index.lookup('METADATA-LOOKUP_TYPE', 'Property', 'HOAMENITIS_Lkp_2'), \
				@index.search('METADATA-LOOKUP_TYPE', {'Resource' => 'Property', 'Lookup' => 'HOAMENITIS_Lkp_2'}).inspect \
				)
		end
=end
	end
end 