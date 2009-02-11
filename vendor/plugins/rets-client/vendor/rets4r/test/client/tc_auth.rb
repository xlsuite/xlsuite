$:.unshift File.join(File.dirname(__FILE__), "../..", "lib")

require 'rets4r/auth'
require 'test/unit'

module RETS4R
	class TestAuth < Test::Unit::TestCase
		def setup
			@useragent  = 'TestAgent/0.00'
			@username   = 'username'
			@password   = 'password'
			@realm      = 'REALM'
			@nonce      =  '2006-03-03T17:37:10'
		end
		
		def test_authenticate
			response = {
				'www-authenticate' => 'Digest qop="auth",realm="'+ @realm +'",nonce="'+ @nonce +'",opaque="",stale="false",domain="\my\test\domain"'
				}
				
			Auth.authenticate(response, @username, @password, '/my/rets/url', 'GET', Auth.request_id, @useragent)
		end
		
		# test without spacing
		def test_parse_auth_header_without_spacing
			header = 'Digest qop="auth",realm="'+ @realm +'",nonce="'+ @nonce +'",opaque="",stale="false",domain="\my\test\domain"'
			check_header(header)
		end
		
		# test with spacing between each item
		def test_parse_auth_header_with_spacing
			header = 'Digest qop="auth", realm="'+ @realm +'", nonce="'+ @nonce +'", opaque="", stale="false", domain="\my\test\domain"'
			check_header(header)
		end
		
		# used to check the that the header was processed properly.
		def check_header(header)
			results = Auth.parse_header(header)
			
			assert_equal('auth', results['qop'])
			assert_equal('REALM', results['realm'])
			assert_equal('2006-03-03T17:37:10', results['nonce'])
			assert_equal('', results['opaque'])
			assert_equal('false', results['stale'])
			assert_equal('\my\test\domain', results['domain'])
		end
		
		def test_calculate_digest
			# with qop
			assert_equal('c5f9ef280f0ca78ed7a488158fc2f4cc', Auth.calculate_digest(@username, \
				@password, @realm, 'test', 'GET', '/my/rets/url', true, 'test'))
			
			# without qop
			assert_equal('bceafa34467a3519c2f6295d4800f4ea', Auth.calculate_digest(@username, \
				@password, @realm, 'test', 'GET', '/my/rets/url', false))
		end
		
		def test_request_id
			assert_not_nil(true, Auth.request_id)
		end
		
		def test_cnonce
			# We call cnonce with a static request ID so that we have a consistent result with which 
			# to test against
			assert_equal('d5cdfa1acffde590d263689fb40cf53c', Auth.cnonce(@useragent, @password, 'requestId', @nonce))
		end
	end
end