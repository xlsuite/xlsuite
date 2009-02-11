#!/usr/bin/ruby
#
# This is an example of how to use the RETS client to login to a server and retrieve metadata. It
# also makes use of passing blocks to client methods and demonstrates how to set the output format.
#
# You will need to set the necessary variables below.
#
#############################################################################################
# Settings

rets_url = 'http://server.com/my/rets/url'
username = 'username'
password = 'password'
  
#############################################################################################
$:.unshift 'lib'

require 'rets4r'

RETS4R::Client.new(rets_url) do |client|
	client.login(username, password) do |login_result|		
		if login_result.success?
			puts "Logged in successfully!"
						
			# We want the raw metadata, so we need to set the output to raw XML.
			client.set_output RETS4R::Client::OUTPUT_RAW
			metadata = ''
			
			begin
				metadata = client.get_metadata
			rescue
				puts "Unable to get metadata: '#{$!}'"
			end
			
			File.open('metadata.xml', 'w') do |file|
				file.write metadata
			end
		else
			puts "Unable to login: '#{login_result.reply_text}'."
		end
	end
end