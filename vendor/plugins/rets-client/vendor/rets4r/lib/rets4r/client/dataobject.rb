module RETS4R
	class Client
		# Represents a RETS object (as returned by the get_object) transaction.
		class DataObject
			attr_accessor :type, :data
			
			alias :info :type
			
			def initialize(type, data)
				self.type = type
				self.data = data
			end
			
			def success?
				return true if self.data
				return false
			end
		end
	end
end