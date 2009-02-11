#!/usr/bin/ruby
#
# This is an example of how to use the RETS client to log in and out of a server. 
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
require 'logger'

client = RETS4R::Client.new(rets_url)
client.logger = Logger.new(STDOUT)

login_result = client.login(username, password)

if login_result.success?
	puts "We successfully logged into the RETS server!"
	
	# Print the action URL results (if any)
	puts login_result.secondary_response
	
	client.logout
	
	puts "We just logged out of the server."
else
	puts "We were unable to log into the RETS server."
	puts "Please check that you have set the login variables correctly."
end