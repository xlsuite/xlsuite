require 'app/models/mail_reader'

class MailReader < ActionMailer::Base
  cattr_accessor :raise_on_receive, :raise_if

  def self.reset_mock!
    @@raise_on_receive = @@raise_if = nil
  end

  alias_method :old_receive, :receive
  def receive(mail)
    should_raise = @@raise_on_receive && @@raise_if.call(mail)
    raise @@raise_on_receive, 'expected exception' if should_raise
    old_receive(mail)
  end
end

MailReader.reset_mock!
