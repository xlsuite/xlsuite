require 'digest/md5'

module RETS4R
	class Auth
		# This is the primary method that would normally be used, and while it 
		def Auth.authenticate(response, username, password, uri, method, requestId, useragent, nc = 0)
			authHeader = Auth.parse_header(response['www-authenticate'])
					
			cnonce = cnonce(useragent, password, requestId, authHeader['nonce'])
			
			authHash = calculate_digest(username, password, authHeader['realm'], authHeader['nonce'], method, uri, authHeader['qop'], cnonce, nc)
			
			header = ''
			header << "Digest username=\"#{username}\", "
			header << "realm=\"#{authHeader['realm']}\", "
			header << "qop=\"#{authHeader['qop']}\", "
			header << "uri=\"#{uri}\", "
			header << "nonce=\"#{authHeader['nonce']}\", "
			header << "nc=#{('%08x' % nc)}, "
			header << "cnonce=\"#{cnonce}\", "
			header << "response=\"#{authHash}\", "
			header << "opaque=\"#{authHeader['opaque']}\""
			
			return header
		end
		
		def Auth.calculate_digest(username, password, realm, nonce, method, uri, qop = false, cnonce = false, nc = 0)				
			a1 = "#{username}:#{realm}:#{password}"
			a2 = "#{method}:#{uri}"
						
			response = '';
			
			requestId = Auth.request_id unless requestId
			
			if (qop)			
				throw ArgumentException, 'qop requires a cnonce to be provided.' unless cnonce
				
				response = Digest::MD5.hexdigest("#{Digest::MD5.hexdigest(a1)}:#{nonce}:#{('%08x' % nc)}:#{cnonce}:#{qop}:#{Digest::MD5.hexdigest(a2)}")
			else
				response = Digest::MD5.hexdigest("#{Digest::MD5.hexdigest(a1)}:#{nonce}:#{Digest::MD5.hexdigest(a2)}")
			end
		
			return response
		end
		
		def Auth.parse_header(header)
			type = header[0, header.index(' ')]
			args = header[header.index(' '), header.length].strip.split(',').map {|x| x.strip}
	
			parts = {'type' => type}
			
			args.each do |arg|
				name, value = arg.split('=')
				
				parts[name.downcase] = value.tr('"', '')
			end
			
			return parts
		end
		
		def Auth.request_id
			Digest::MD5.hexdigest(Time.new.to_f.to_s)
		end
		
		def Auth.cnonce(useragent, password, requestId, nonce)
			Digest::MD5.hexdigest("#{useragent}:#{password}:#{requestId}:#{nonce}")
		end
	end
end