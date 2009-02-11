require File.dirname(__FILE__) + '/../test_helper'
require 'party_notification'

class PartyNotificationTest < Test::Unit::TestCase
  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @bob = parties(:bob)
  end

  def test_random_password
    mail = PartyNotification.create_password_reset(
      :party => @bob, :username => @bob.main_email.address,
      :username => @bob.main_email.address,
      :password => 'tango',
      :site_name => 'XLsuite.com')

    assert mail.to.include?(@bob.main_email.address),
        "Bob is in the recipients list"
    assert_match /login:\s+#{Regexp.escape(@bob.main_email.address)}\b/i, mail.body
    assert_match /password:\s+tango\b/i, mail.body
  end
end
