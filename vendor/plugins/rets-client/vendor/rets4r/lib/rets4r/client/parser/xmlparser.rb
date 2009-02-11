# Because XMLParser may not be present on this system, we attempt to require it and if it
# succeeds, we create the XMLParser and add it to the supported parsers. The user of the client 
# can still switch to REXML if desired.
begin
	require 'xml/parser'
	require 'rets4r/client/parser'
	require 'rets4r/client/transaction'
	require 'rets4r/client/data'
	require 'rets4r/client/metadata'
	
	module RETS4R
		class Client
			module Parser
				class XMLParser < XML::Parser
					include Parser
					
					SUPPORTED_PARSERS << self
						
					attr_accessor :logger
					
					def initialize
						@transaction = Transaction.new
						@current	   = []
						@text        = ''
					end
					
					def parse(xml, output = false, do_retry = true)			
						begin
							super(xml)
						rescue XMLParserError
								line = self.line
							
								# We should get fancier here and actually check the type of error, but, err, oh well.
								if do_retry			  		
									# We probably received this error because somebody forgot to escape XML entities...
									# so we attempt to escape them ourselves...													
									do_retry = false
									
									begin
										cleaned_xml = self.clean_xml(xml)
										
										# Because a cparser can only be used once per instantiation...
										retry_xml = self.class.new
										retry_xml.parse(cleaned_xml, output, do_retry)
										
										@transaction = retry_xml.get_transaction
										
									rescue
										ex = ParserException.new($!)
										ex.file = xml
		
										raise ex
									end
							else
								# We should never get here! But if we do...
								raise "You really shouldn't be seeing this error message! This means that there was an unexpected error: #{$!} (#{$!.class})"
							end
						end
									
						@transaction
					end
					
					def get_transaction
						@transaction
					end
					
					private
					
					#### Stream Listener Events
					def startElement(name, attrs)		
						tag_start(name, attrs)
					end
					
					def character(text)
						@text += text
					end
					
					def processText()
						text(@text)
						
						@text = ''
					end
					
					def endElement(name)
						processText()
						
						tag_end(name)
					end
				end
			end
		end
	end 
rescue LoadError
	# CParser is not available because we could not load the XMLParser library	
end