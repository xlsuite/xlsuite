#!/usr/bin/ruby
#
# This is an example of how to use the RETS client to retrieve an objet.
#
# You will need to set the necessary variables below.
#
#############################################################################################
# Settings

rets_url = 'http://server.com/my/rets/url'
username = 'username'
password = 'password'

# GetObject Settings
resource    = 'Property'
object_type = 'Photo'
resource_id = 'id:*'

#############################################################################################
$:.unshift 'lib'

require 'rets4r'
require 'logger'

def handle_object(object)
	case object.info['Content-Type']
		when 'image/jpeg' then extension = 'jpg'
		when 'image/gif'  then extension = 'gif'
		when 'image/png'  then extension = 'png'
		else extension = 'unknown'
	end

	File.open("#{object.info['Content-ID']}_#{object.info['Object-ID']}.#{extension}", 'w') do |f|
		f.write(object.data)
	end
end

client = RETS4R::Client.new(rets_url)

client.login(username, password) do |login_result|
	
	if login_result.success?
		## Method 1
		# Get objects using a block
		client.get_object(resource, object_type, resource_id) do |object|
			handle_object(object)
		end
		
		## Method 2
		# Get objects using a return value
		results = client.get_object(resource, object_type, resource_id)
		
		results.each do |object|
			handle_object(object)
		end
	else
		puts "We were unable to log into the RETS server."
		puts "Please check that you have set the login variables correctly."
	end
end