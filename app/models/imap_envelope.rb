#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ImapEnvelope
  attr_reader :envelope

  attr_reader :from_raw_address

  attr_reader :tos_raw_address
  attr_reader :cc_raw_address
  attr_reader :bcc_raw_address
  
  attr_reader :date, :subject, :message_id, :in_reply_to
  
  def initialize(imap_envelope)
    @envelope = imap_envelope
    @from_raw_address = @envelope.from.first
    
    @tos_raw_address = @envelope.to
    @ccs_raw_address = @envelope.cc
    @bccs_raw_address = @envelope.bcc
    
    @date = Time.parse(@envelope.date)
    @subject = @envelope.subject
    @message_id = @envelope.message_id
    @in_reply_to = @envelope.in_reply_to
  end
  
  def from_address
    @from_raw_address.mailbox + "@" + @from_raw_address.host
  end
  
  def from_name_with_address
    if @from_raw_address.name
      @from_raw_address.name + " <" + self.from_address + ">"
    else
      self.from_address
    end
  end
  
  def from_name_or_address
    if @from_raw_address.name
      @from_raw_address.name
    else
      self.from_address
     end
  end
  
  %w(tos ccs bccs).each do |target|
    class_eval <<-EOF
      def #{target}_name_with_address
        out = []
        return out unless @#{target}_raw_address
        @#{target}_raw_address.each do |raw_address|
          if raw_address.name
            out << (raw_address.name + " <" + raw_address.mailbox + "@" + raw_address.host + ">")
          else
            out << (raw_address.mailbox + "@" + raw_address.host)
          end
        end
        out
      end
      
      def #{target}_address
        out = []
        return out unless @#{target}_raw_address
        @#{target}_raw_address.each do |raw_address|
          out << (raw_address.mailbox + "@" + raw_address.host)
        end
        out
      end
      
      def #{target}_name_or_address
        out = []
        return out unless @#{target}_raw_address
        @#{target}_raw_address.each do |raw_address|
          if raw_address.name
            out << raw_address.name
          else
            out << (raw_address.mailbox + "@" + raw_address.host)
          end
        end
        out
      end
    EOF
  end
end
