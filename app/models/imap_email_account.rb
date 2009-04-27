#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ImapEmailAccount < EmailAccount  
  EXCEPTION_SERVERS = ["imap.google.com"]
  EXCEPTION_NAMES = ["Google Mail"]
  EXCEPTION_PORTS = [993]

  DEFAULT_SELECTIONS = EXCEPTION_NAMES + ["Other"]
  LOCALHOST = "127.0.0.1"
  
  def default_server_name
    return EXCEPTION_NAMES[0] if self.server.blank?
    index = EXCEPTION_SERVERS.index(self.server)
    if index
      EXCEPTION_NAMES[index]
    else
      DEFAULT_SELECTIONS[-1]
    end
  end
  
  def default_server
    return EXCEPTION_SERVERS[0] if self.server.blank?
    self.server
  end
  
  def default_port
    return EXCEPTION_PORTS[0] if self.port.blank?
    self.port
  end
  
  def connecting_server
    return LOCALHOST if EXCEPTION_SERVERS.include?(self.server)
    self.server
  end
  
  def connecting_port
    index = EXCEPTION_SERVERS.index(self.server)
    if index
      return EXCEPTION_PORTS[index]
    else
      self.port
    end
  end
  
  def test
    out = nil
    imap = nil
    begin
      imap = Net::IMAP.new(self.connecting_server, self.connecting_port)
      authenticate = imap.login(self.username, self.password)
      self.set_enabled(true)
      out = [true]
    rescue Errno::ECONNRESET
      self.set_enabled(false)
      out = [false, "Connection failed, please check your IMAP setting. If problem persist contact your administrator."]
    rescue Net::IMAP::NoResponseError
      self.set_enabled(false)
      message = $!.message.to_s + ". Please check your IMAP setting."
      out = [false, message]
    ensure
      imap.disconnect if imap
    end
    out
  end
end
