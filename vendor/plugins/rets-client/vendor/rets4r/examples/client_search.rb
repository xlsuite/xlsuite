#!/usr/bin/ruby
#
# This is an example of how to use the RETS client to perform a basic search.
#
# You will need to set the necessary variables below.
#
#############################################################################################
# Settings

rets_url = 'http://server.com/my/rets/url'
username = 'username'
password = 'password'

rets_resource = 'Property'
rets_class    = 'Residential'
rets_query    = '(RetsField=Value)'

#############################################################################################
$:.unshift 'lib'

require 'rets4r'

client = RETS4R::Client.new(rets_url)

logger = Logger.new($stdout)
logger.level = Logger::WARN
client.logger = logger

login_result = client.login(username, password)

if login_result.success?
	puts "We successfully logged into the RETS server!"
	
	options = {'Limit' => 5}
	
	client.search(rets_resource, rets_class, rets_query, options) do |result|
		result.data.each do |row|
			puts row.inspect
			puts
		end
	end
	
	client.logout
	
	puts "We just logged out of the server."
else
	puts "We were unable to log into the RETS server."
	puts "Please check that you have set the login variables correctly."
end

logger.close