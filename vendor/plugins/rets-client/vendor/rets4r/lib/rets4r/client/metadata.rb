require 'rets4r/client/data'

module RETS4R
	class Client
		# Represents a set of metadata. It is simply an extended Array with type and attributes accessors.
		class Metadata < Array
			attr_accessor :type, :attributes
			
			def initialize(type = false)
				self.type = type if type
				self.attributes = {}
			end
		end
	end
end