# This is the generic parser 
#
#	Supports responses, data, metadata, reply codes, and reply text.
#
#	Supports the following tags:
#		RETS, METADATA-.*, MAXROWS, COLUMNS, DATA, COUNT, DELIMITER
#
#	Metadata is built as:
#		(Metadata 1-> data row
#		           -> data row),
#		(Metadata 2 -> data row),
#		etc.
#
#	Data is built as:
#		Data 1, Data 2, Data N
#
#
#	TODO
#		Add comments/documentation
#		Handle more tags (if any are unaccounted for)
#   Handle standard (non-compact) output
#		Case Insensitivity?
# 	There is still some holdovers from the previous organization of parsers, and they should be cleaned
# 	  up at some point.

require 'cgi'

module RETS4R
	class Client
		module Parser			
			attr_accessor :output, :logger
			
			def initialize
				@transaction = Transaction.new
				@current	   = []
				@output      = 2
			end
			
			def get_transaction
				@transaction
			end
					
			#### Stream Listener Events
			def tag_start(name, attrs)		
				@current.push(name)
	
				case name
					when 'RETS'
						@transaction.reply_code = attrs['ReplyCode']
						@transaction.reply_text = attrs['ReplyText']
					when /METADATA.*/
						@metadata = Metadata.new(name)
						@metadata.attributes = attrs
					when 'MAXROWS'
						@transaction.maxrows = true
					when 'COUNT'
						@transaction.count     = attrs['Records'].to_i
					when 'DELIMITER'
						@transaction.delimiter = attrs['value'].to_i
				end
			end
			
			def text(text)
				case @current[-1]
					when 'COLUMNS'
						@transaction.header = parse_compact_line(text, @transaction.ascii_delimiter)
						
					when 'DATA'
						if @transaction.header.length > 0
							data_type << parse_data(text, @transaction.header)
						else
							data_type << parse_compact_line(text, @transaction.ascii_delimiter)
						end
					
					when 'RETS-RESPONSE'
						@transaction.response = parse_key_value_body(text)
				end
			end
			
			def tag_end(name)
				@current.pop
				
				@transaction.data << @metadata if name =~ /METADATA.*/
			end
			
			#### Helper Methods
			def clean_xml(xml)				
				# This is a hack, and it assumes that we're using compact mode, but it's the easiest way to
				# strip out those bad "<" and ">" characters that were not properly escaped...
				xml.gsub!(/<DATA>(.*)<\/DATA>/i) do |match|
					"<DATA>#{CGI::escapeHTML(CGI::unescapeHTML($1))}</DATA>"
				end
			end
			
			def data_type
				if @current[-2].index('METADATA') === 0
					return @metadata
				else
					return @transaction.data
				end
			end
			
			def parse_compact_line(data, delim = "\t")
				begin
					return data.to_s.strip.split(delim)
				rescue
					raise "Error while parsing compact line: #{$!} with data: #{data}"
				end
			end
			
			def parse_data(data, header)			
				results = Data.new(@current[-2])
				
				parsed_data = parse_compact_line(data, @transaction.ascii_delimiter)
				
				header.length.times do |pos|
					results[header[pos]] = parsed_data[pos]
				end
				
				results
			end
			
			def parse_key_value_body(data)
				parsed = {}
				
				data.each do |line|
					(key, value) = line.strip.split('=')
					parsed[key] = value
				end
				
				return parsed
			end
		end
	end
end