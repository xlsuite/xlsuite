module RETS4R
	class Client
		# Provides a means of indexing metadata to allow faster searching of it.
		# This is in dire need of a review and cleanup, so I advise you not to use it until that has been done.
		class MetadataIndex
			# Constructor that takes an array of Metadata objects as its sole argument.
			def initialize(metadata)
				@metadata 	= metadata
				@index	= index(@metadata)
			end
			
			# WARNING! Not working properly (does NOT pass unit test)
			# This is more of a free form search than #lookup, but it is also slower because it must iterate
			# through the entire metadata array. This also returns multiple matches, which #lookup doesn't do.
			def search(type, attributes = {})
				matches = []
				
				@metadata.each do |meta|
					catch :mismatch do
						if meta.type == type
							attributes.each do |k,v|
								throw :mismatch unless meta.attributes[k] == v
							end
							
							matches << meta
						end
					end
				end
				
				return matches
			end
			
			# This is a streamlined and probably the preferred method for looking up metadata because it
			# uses a index to quickly access the data. The downside is that it is not very flexible. This also
			# only returns one (the "best") match. If you need multiple matches, then you should use #search.
			# Tests show about a 690% speed increase by using #lookup over #search, so you've been warned.
			def lookup(type, *attributes)
				key = type
				key << attributes.join('')
				
				@index[key]
			end
			
			private
			
			# Provided an array of metadata, it indexes it for faster lookup.
			# Takes a +Metadata+ object as its argument.
			def index(metadata)
				index = {}
				
				metadata.each do |meta|
					key = generate_key(meta)
					
					index[key] = meta
				end
				
				return index
			end
			
			# Used to generate the key for a specified piece of metadata. Takes a +Metadata+ object as its
			# argument.
			def generate_key(meta)
				key = meta.type
					
				case (meta.type)
					when 'METADATA-LOOKUP'
						key << meta.attributes['Resource']
					when 'METADATA-LOOKUP_TYPE'
						key << meta.attributes['Resource'] << meta.attributes['Lookup']
					when 'METADATA-CLASS'
						key << meta.attributes['Resource']
					when 'METADATA-OBJECT'
						key << meta.attributes['Resource']
					when 'METADATA-TABLE'
						key << meta.attributes['Resource'] << meta.attributes['Class']
				end
				
				return key
			end
		end
	end
end