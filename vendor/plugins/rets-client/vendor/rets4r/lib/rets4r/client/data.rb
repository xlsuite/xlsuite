module RETS4R
	class Client
		# Represents a row of data. Nothing more than a glorfied Hash with a custom constructor and a
		# type attribute.
		class Data < ::Hash
			attr_accessor :type
			
			def initialize(type = false)
				super
				self.type = type
			end
		end
	end
end 