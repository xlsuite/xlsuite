require 'rets4r/client/parser'
require 'rexml/parsers/baseparser'
require 'rexml/parsers/streamparser'
require 'rexml/streamlistener'
require 'rets4r/client/transaction'
require 'rets4r/client/data'
require 'rets4r/client/metadata'

module RETS4R
	class Client
		module Parser
			class REXML
				include Parser

				SUPPORTED_PARSERS << self
				
				attr_accessor :logger
				
				def initialize
					@transaction = Transaction.new
					@current	   = []
				end
				
				def parse(xml, output = false, do_retry = true)
					output = self.output unless output # Allow per-parse output changes
					
					return xml if output == OUTPUT_RAW
					
					# This is an legacy option that is not currently supported by XMLParser, but it is left in
					# here for reference or "undocumented usage."
					if output == OUTPUT_DOM
						return ::REXML::Document.new(xml)
					end			
					
					# If we're here, then we need to output a RETS::Data object
					listener = StreamListener.new
					
					begin
						stream = ::REXML::Parsers::StreamParser.new(xml, listener)
						stream.parse
					rescue ::REXML::ParseException, Exception
						# We should get fancier here and actually check the type of error, but, err, oh well.
						if do_retry
							logger.info("Unable to parse XML on first try due to '#{$!}'. Now retrying.") if logger
							
							return parse(clean_xml(xml), output, false)
						else
							ex = ParserException.new($!)
							ex.file = xml
							
							logger.error("REXML parser was unable to parse XML: #{$!}") if logger
							logger.error("Unparsable XML was:\n#{xml}") if logger
							
							raise ex
						end
					end
					
					return listener.get_transaction
				end
				
				class StreamListener
					include ::REXML::StreamListener
					include Parser				

					def initialize(logger = nil)
						self.logger  = logger
						@transaction = Transaction.new
						@current	   = []
						@output      = 2
					end
				end
			end
		end
	end
end	