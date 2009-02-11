require 'net/pop'

module Net #:nodoc:
  class POP3 < Net::Protocol #:nodoc:
    cattr_accessor :address, :port, :account, :password
    attr_accessor :mails, :fail_on_start

    def self.instance=(instance)
      @@instance = instance
    end

    def self.start(*args)
      @@address, @@port, @@account, @@password = *args
      raise Net::POPError if @@instance.fail_on_start
      yield(@@instance) if @@instance && block_given?
    end

    def initialize(*args)
    end
  end

  class POPMail #:nodoc:
    attr_accessor :pop

    def initialize(*args)
    end

    def uidl
      Digest::MD5.hexdigest(self.object_id.to_s + self.pop)
    end
  end
end
