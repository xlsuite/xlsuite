$:.unshift File.join(File.dirname(__FILE__), "../..", "lib")

require 'rets4r/client'
require 'test/unit'
require 'stringio'
require 'logger'
require 'rubygems' rescue nil
require 'mocha'

module RETS4R
	class Client
		public :process_content_type
	end
	
	class TestClientGetMetadata < Test::Unit::TestCase
		RETS_PORT     = '9080'
		RETS_URL      = "http://localhost:#{RETS_PORT}"
		RETS_LOGIN    = 'login'
		RETS_PASSWORD = 'password'
		
		class CustomError < StandardError; end
		
		def setup
			@logfile = StringIO.open
			@rets    = RETS4R::Client.new(RETS_URL)
			@rets.logger = Logger.new(@logfile)
			@rets.logger.level = Logger::DEBUG
			
			@rets.stubs(:request).returns(@response = mock("response"))
			@response.stubs(:body).returns(:body)
			@rets.stubs(:parse).returns(@results = mock("results"))
		end

		def teardown
			@logfile.close
		end
		
		def test_get_metadata_yields_the_results_if_given_a_block
			@rets.expects(:parse).returns(@results = mock("results"))
			
			in_block = false
			@rets.get_metadata do |results|
				in_block = true
				assert_equal @results, results
			end
			
			assert in_block, "Block was never yielded to"
		end
		
		def test_get_metadata_returns_the_metadata_when_no_block_given
			rval = @rets.get_metadata
			
			assert_equal @results, rval
		end
		
		def test_get_metadata_returns_the_blocks_value_when_given_a_block
			rval = @rets.get_metadata do |results|
				:block_value
			end
			
			assert_equal :block_value, rval
		end
	end
	
	class TestClientGetObject < Test::Unit::TestCase
		RETS_PORT     = '9080'
		RETS_URL      = "http://localhost:#{RETS_PORT}"
		RETS_LOGIN    = 'login'
		RETS_PASSWORD = 'password'
		
		class CustomError < StandardError; end
		
		def setup
			@logfile = StringIO.open
			@rets    = RETS4R::Client.new(RETS_URL)
			@rets.logger = Logger.new(@logfile)
			@rets.logger.level = Logger::DEBUG

			@rets.stubs(:request).returns(@response = mock("response"))
		end

		def test_returns_multipart_parallel_objects_in_a_single_array
			@response.expects(:[]).with('content-type').at_least_once.returns("multipart/parallel; boundary=1231")
			@response.expects(:body).returns("\r\n--1231\r\nContent-ID: 392103\r\nObject-ID: 1\r\nContent-Type: image/jpeg\r\n\r\n" + "\000"*120 + "\r\n--1231\r\nContent-ID: 392103\r\nObject-ID: 2\r\nContent-Type: image/gif\r\n\r\n" + "\000"*140 + "\r\n--1231--")
			results = @rets.get_object("Property", "Photo", "392103:*")
			assert_equal 2, results.size, "Client parsed two objects out of the request"
			assert_kind_of RETS4R::Client::DataObject, results[0], "First result isn't a DataObject"
			assert_kind_of RETS4R::Client::DataObject, results[1], "Second result isn't a DataObject"
			assert_equal "image/jpeg", results[0].type["Content-Type"], "First object isn't an image/jpeg"
			assert_equal 120, results[0].data.size, "First object isn't 120 bytes in length"
			assert_equal "image/gif", results[1].type["Content-Type"], "Second object isn't an image/gif"
			assert_equal 140, results[1].data.size, "Second object isn't 140 bytes in length"
		end

		def test_returns_single_entity_object_in_a_single_element_array
			@response.expects(:[]).with('content-type').at_least_once.returns("image/jpeg")
			@response.expects(:[]).with('Transfer-Encoding').at_least_once.returns("")
			@response.expects(:[]).with('Content-Length').at_least_once.returns(241)
			@response.expects(:[]).with('Object-ID').at_least_once.returns("25478")
			@response.expects(:[]).with('Content-ID').at_least_once.returns("5589")
			@response.expects(:body).returns("\000"*241)

			results = @rets.get_object("Property", "Photo", "392103:*")
			assert_equal 1, results.size, "Client parsed one object out of the request"
			assert_kind_of RETS4R::Client::DataObject, results[0], "First result isn't a DataObject"
			assert_equal "image/jpeg", results[0].type["Content-Type"], "Content-Type not copied"
			assert_equal "5589", results[0].type["Content-ID"], "Content-ID not copied"
			assert_equal "25478", results[0].type["Object-ID"], "Object-ID not copied"
			assert_equal 241, results[0].data.size, "First object isn't 241 bytes in length"
		end

		def test_returns_single_entity_object_as_chunked_encoding_in_a_single_element_array
			@response.expects(:[]).with('content-type').at_least_once.returns("image/jpeg")
			@response.expects(:[]).with('Transfer-Encoding').at_least_once.returns("chunked")
			@response.expects(:[]).with('Object-ID').at_least_once.returns("25478")
			@response.expects(:[]).with('Content-ID').at_least_once.returns("5589")
			@response.expects(:body).returns("\000"*241)

			results = @rets.get_object("Property", "Photo", "392103:*")
			assert_equal 1, results.size, "Client parsed one object out of the request"
			assert_kind_of RETS4R::Client::DataObject, results[0], "First result isn't a DataObject"
			assert_equal "image/jpeg", results[0].type["Content-Type"], "Content-Type not copied"
			assert_equal "5589", results[0].type["Content-ID"], "Content-ID not copied"
			assert_equal "25478", results[0].type["Object-ID"], "Object-ID not copied"
			assert_equal 241, results[0].data.size, "First object isn't 241 bytes in length"
		end

		def test_yields_data_objects_to_block_and_returns_blocks_value
			@response.expects(:[]).with('content-type').at_least_once.returns("image/jpeg")
			@response.expects(:[]).with('Transfer-Encoding').at_least_once.returns("")
			@response.expects(:[]).with('Content-Length').at_least_once.returns(241)
			@response.expects(:[]).with('Object-ID').at_least_once.returns("25478")
			@response.expects(:[]).with('Content-ID').at_least_once.returns("5589")
			@response.expects(:body).returns("\000"*241)

			yielded_count = 0
			
			value = @rets.get_object("Property", "VRImage", "912:0") do |result|
				assert_kind_of RETS4R::Client::DataObject, result	
				yielded_count += 1
				:return_value
			end

			assert_equal yielded_count, value
		end
	end
	
	class TestClientLogin < Test::Unit::TestCase
		RETS_PORT     = '9080'
		RETS_URL      = "http://localhost:#{RETS_PORT}"
		RETS_LOGIN    = 'login'
		RETS_PASSWORD = 'password'
		
		class CustomError < StandardError; end
		
		def setup
			@logfile = StringIO.open
			@rets    = RETS4R::Client.new(RETS_URL)
			@rets.logger = Logger.new(@logfile)
			@rets.logger.level = Logger::DEBUG

			@rets.stubs(:request).returns(@response = mock("response"))
			@response.stubs(:body).returns(:body)
			@rets.stubs(:parse).returns(@results = mock("results"))
			@results.stubs(:success?).returns(true)
			@results.stubs(:response).returns(Hash.new)
			@results.stubs(:secondary_response=)
		end

		def teardown
			@logfile.close
		end

		def test_successful_login_yields_the_results_to_the_block
			@rets.expects(:request).with {|arg| arg.kind_of?(URI)}.returns(@response)
			@rets.expects(:parse).with(:body, RETS4R::Client::OUTPUT_RUBY).returns(@results)
			@results.expects(:success?).returns(true)
			@rets.expects(:logout)

			in_block = false
			@rets.login("user", "pass") do |results|
				assert_equal @results, results
				in_block = true
			end
			
			assert in_block, "Block was never yielded to"
		end

		def test_logout_called_after_block_execution_if_block_raises
			assert_raises(CustomError) do
				@rets.expects(:logout)
				@rets.login("user", "pass") do |results|
					raise CustomError
				end
			end
		end
		
		def test_login_returns_the_blocks_value
			rval = @rets.login("user", "pass") do |results|
				:value
			end
			
			assert_equal :value, rval
		end
		
		def test_login_without_a_block_returns_the_results
			results = @rets.login("user", "pass")
			assert_equal @results, results
		end
	end
	
	class TestClient < Test::Unit::TestCase
		RETS_PORT     = '9080'
		RETS_URL      = "http://localhost:#{RETS_PORT}"
		RETS_LOGIN    = 'login'
		RETS_PASSWORD = 'password'
		
		def setup
			@logfile = StringIO.open
			@rets    = RETS4R::Client.new(RETS_URL)
			@rets.logger = Logger.new(@logfile)
			@rets.logger.level = Logger::DEBUG
		end

		def teardown
			@logfile.close
		end
		
		def test_setup
			assert_nothing_raised() { @rets.set_user_agent('ACK/2.1') }
			assert_equal('ACK/2.1', @rets.user_agent)

			assert_nothing_raised() { @rets.user_agent = 'SPRETS/0.1' }
			assert_nothing_raised() { @rets.set_request_method('GET') }
			
			assert_raise(RETS4R::Client::Unsupported) { @rets.set_rets_version('1.4.0') }
			assert_nothing_raised() { @rets.set_rets_version('1.5') }
			assert_equal("1.5", @rets.rets_version)
			assert_equal("RETS/1.5", @rets.get_header("RETS-Version"))
			assert_nothing_raised() { @rets.rets_version = '1.7' }
			assert_equal("RETS/1.7", @rets.get_header("RETS-Version"))
			
			assert_equal('SPRETS/0.1', @rets.get_user_agent)
			assert_equal('GET', @rets.get_request_method)
			assert_equal('1.7', @rets.get_rets_version)
			
			assert_nothing_raised() { @rets.request_method = 'POST' }
			
			assert_equal('POST', @rets.request_method)
			
			assert_nothing_raised() { @rets.set_parser_class(Client::Parser::REXML) }
			assert_raise(Client::Unsupported) { @rets.parser_class = MockParser }
			assert_nothing_raised() { @rets.set_parser_class(MockParser, true) }
			assert_equal(MockParser, @rets.parser_class)
			
			assert_nothing_raised() { @rets.set_output(RETS4R::Client::OUTPUT_RAW) }
			assert_equal(RETS4R::Client::OUTPUT_RAW, @rets.output)
			assert_nothing_raised() { @rets.output = RETS4R::Client::OUTPUT_RUBY }
			assert_equal(RETS4R::Client::OUTPUT_RUBY, @rets.get_output)
			
			# Check that our changes were logged when in debug mode
			assert @logfile.length > 0
		end
		
		# Just to make sure that we're okay when we don't have a logger, we set it to nil and
		# make a change that would trigger a debug mode log.
		def test_without_logger
			@rets.logger = nil
			
			assert_nothing_raised() { @rets.set_request_method('GET') }
		end
		
		def test_content_type_parsing
			ct = 'multipart/parallel; boundary=cc2631bb.0165.3b32.8a7d.a8453f662101; charset=utf-8'
			
			results = @rets.process_content_type(ct)

			assert_equal('cc2631bb.0165.3b32.8a7d.a8453f662101', results['boundary'])
			assert_equal('multipart/parallel', results['content-type'])
			assert_equal('utf-8', results['charset'])
		end
						
		class MockParser
		end
	end
end 