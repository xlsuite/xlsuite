module ActionMailer
  class Base
    adv_attr_accessor :alternate_smtp_settings
    private
      def perform_delivery_smtp(mail)
        destinations = mail.destinations
        mail.ready_to_send
        sender = mail['return-path'] || mail.from
        
        settings = self.alternate_smtp_settings
        settings = smtp_settings unless settings

        Net::SMTP.start(settings[:address], settings[:port], settings[:domain],
            settings[:user_name], settings[:password], settings[:authentication]) do |smtp|
          smtp.sendmail(mail.encoded, sender, destinations)
        end
      end
  end
end
