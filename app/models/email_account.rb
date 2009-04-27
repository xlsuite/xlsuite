#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class EmailAccount < ActiveRecord::Base
  validates_presence_of :server, :port, :username, :password, :account_id
  validates_inclusion_of :port, :within => 1..65535
  
  belongs_to :account
  belongs_to :party

  has_many :shared_email_accounts

  def access_method
    self.class.name.gsub('EmailAccount', '').upcase
  end

  def access_method=(value)
    # NOP
  end

  # Retrieve up to +max_count+ mail messages from the account, and don't take more
  # than +timeout+ seconds to do it.  If a timeout error occurs, the transaction
  # *will not be rolled back*.  If another error occurs, the transaction is rolled
  # back.
  def retrieve!(max_count=10000, timeout=2.minutes)
    transaction do
      begin
        Timeout::timeout(timeout) do
          self.new_mails do |mail|
            max_count -= 1
            break nil if max_count < 0

            begin
              MailReader.account = self.account
              MailReader.user = self.party
              MailReader.receive(mail)
            rescue
              logger.error {"Error receiving mail: #{$!}\n#{$!.backtrace.join("\n")}"}
              nil
            end
          end
        end
        self.update_attributes({:error_message => nil, :failures => 0})
      rescue Timeout::Error
        # NOP, we want the emails to be saved
      end
    end
    rescue
      failures = self.failures
      if failures >= 2
        self.update_attributes({:error_message => $!.message, :failures => failures+1}) 
      else
        self.update_attribute(:failures, failures+1)
      end
      #retrieve! failed; must raise exception
      raise
  end
  
  def self.find_by_name(string)
    self.class.find_by_email_address(string)
  end

  def self.get_next_ready
    EmailAccount.find(:first, :order => "updated_at", :conditions => "error_message IS NULL AND failures < 3")
  end

  def set_enabled(flag)
    value = flag ? "1" : "0"
    self.class.update_all("enabled = #{value}", "id = #{self.id}")    
  end
  
  protected
  # Must yield the raw E-Mail text (once per new E-Mail) and must return an
  # Email instance.  E-Mails that have already been processed MUST NOT be
  # yielded anew.
  def new_mails
    raise "Subclass responsibility"
  end
end
