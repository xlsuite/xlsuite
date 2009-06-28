#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require 'enumerator'

class Email < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id

  belongs_to :domain
  has_many :mass_recipients, :class_name => "MassRecipient", :dependent => :delete_all, :foreign_key => "email_id", :extend => Extensions::MassRecipients
  validate :ccs_and_bccs_is_empty

  after_save :build_tos
  after_save :build_ccs
  after_save :build_bccs

  ValidMailTypes = %w(HTML Plain HTML+Plain).freeze
  validates_inclusion_of :mail_type, :in => ValidMailTypes

  def domain_name
    self.domain.name
  end

  # The tags on Email itself relate to the +sender+, not any of the recipients.
  # The tags on Recipient relate to that recipient only.
  acts_as_taggable
  acts_as_fulltext %w(subject recipients_as_text dates_as_text tag_list)

  # We record the last exception's backtrace to help us trace the root cause of the problem.
  serialize :backtrace

  belongs_to :smtp_email_account

  has_many :attachments
  has_many :assets, :through => :attachments

  belongs_to :about, :polymorphic => true
  has_many :emails, :as => :about

  has_and_belongs_to_many :filters

  # A secondary recipient is created when the same email from a same pop3 account
  # is retrieved by another party
  has_many :secondaries, :class_name => "SecondaryRecipient", :dependent => :delete_all

  has_many :tos, :class_name => "ToRecipient", :dependent => :delete_all, :extend => Extensions::Recipients
  has_many :bccs, :class_name => "BccRecipient", :dependent => :delete_all, :extend => Extensions::Recipients
  has_many :ccs, :class_name => "CcRecipient", :dependent => :delete_all, :extend => Extensions::Recipients

  has_one :sender, :dependent => :delete
  validate :sender_cant_be_blank

  # Keep the parsed bodies and subjects around, so we
  # only have to do data interpolation at sending time.
  validate :verify_liquid_templates_syntax
  after_validation :dump_liquid_templates

  attr_accessor :current_user

  def mailbox
    return "inbox" if self.received_at
    return "outbox" if self.released_at && self.sent_at.nil?
    return "draft" if self.released_at.nil? && self.sent_at.nil? && self.received_at.nil?
    return "sent" if self.sent_at
    return nil
  end

  def to_s
    self.subject.to_s.inspect
  end

  #for email filters
  def apply_filters(user)
    return if user.blank?
    logger.debug("^^^Applying filter to email# #{self.id}")
    user.filters.each do |filter|
      all_lines_passed = true
      filter.filter_lines.each do |line|
        logger.debug("^^^Field: #{line.field}")
        case line.operator
        when "eq"
          regex = /^#{line.value}$/
        when "start"
          regex = /^#{line.value}/
        when "end"
          regex = /#{line.value}$/
        when "contain"
          regex = /#{line.value}/
        end
        case line.field
        when "from"
          match = line.exclude ? !(self.sender.address =~ regex) : self.sender.address =~ regex
          all_lines_passed = all_lines_passed && match
        when "to"
          tos_passed = false
          %w(tos bccs ccs).each do |recipient_type|
            self.send(recipient_type).each do |recipient|
              tos_passed = tos_passed || recipient.address =~ regex
              break if tos_passed
            end
            break if tos_passed
          end
          all_lines_passed = all_lines_passed && (line.exclude ? !tos_passed : tos_passed)
        when "subject"
          all_lines_passed = all_lines_passed && (line.exclude ? !(self.subject =~ regex) : self.subject =~ regex)
        when "body"
          all_lines_passed = all_lines_passed && (line.exclude ? !(self.body =~ regex) : self.body =~ regex)
        end
      end
      filter.emails << self if all_lines_passed
    end
  end

  def self.find_my_emails_with_users(user_ids, current_account, current_user)
    user_ids_arr = []
    user_ids.split(',').each{|id| user_ids_arr << id.to_i} unless user_ids.blank?

    return [] if user_ids_arr.empty?
    user_email_ids = Email.connection.select_values("SELECT DISTINCT email_id FROM recipients WHERE recipients.party_id = #{current_user.id}")
    record_email_ids = Email.connection.select_values("SELECT DISTINCT email_id FROM recipients WHERE recipients.party_id IN (#{user_ids_arr.join(',')})")

    email_ids = user_email_ids & record_email_ids

    return [] if email_ids.empty?

    Email.find(:all, :order => 'CONCAT_WS("", emails.sent_at, emails.received_at) DESC', :limit => 30,
      :conditions => ["emails.id IN (#{email_ids.join(',')}) AND (emails.sent_at IS NOT NULL OR emails.received_at IS NOT NULL)"])
  end

  def self.find_users_emails(user_ids, current_account)
    user_ids_arr = []
    user_ids.split(',').map(&:strip).each{|id| user_ids_arr << id.to_i} unless user_ids.blank?

    return [] if user_ids_arr.empty?
    email_ids = Email.connection.select_values("SELECT DISTINCT email_id FROM recipients WHERE recipients.party_id IN (#{user_ids_arr.join(',')})").reject(&:blank?)
    return [] if email_ids.empty?

    # We do not fear a SQL injection attack for email_ids, because we just got it from the database itself.
    Email.find(:all, :order => 'CONCAT_WS("", emails.sent_at, emails.received_at) DESC', :limit => 30,
      :conditions => "emails.id IN (#{email_ids.join(',')}) AND (emails.sent_at IS NOT NULL OR emails.received_at IS NOT NULL)")
  end

  def read_by(user, time=Time.now)
    [self.tos, self.ccs, self.bccs, self.secondaries].map {|coll| coll.find_by_party_id(user.id)}.compact.each do |party|
      party.update_attribute(:read_at, time)
    end
  end

  def to_xml(options={})
    options[:indent] ||= 2
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.email(:id => self.dom_id) do
      xml.tag! "date", self.received_at.to_date
      xml.tag! "from", self.sender.address
      xml.tag! "subject", self.subject
      xml.tag! "hasCompleted", self.sender.read_at? ? "true" : "false"
      xml.tag! "body", self.body
    end
  end

  def total_number_of_recipients
    [self.tos(true), self.ccs(true),
        self.bccs(true)].flatten.map(&:email_addresses).flatten.size
  end

  def tos=(*recipients)
    @_tos = recipients.flatten
  end

  def ccs=(*recipients)
    return if self.mass_mail?
    @_ccs = recipients.flatten
  end

  def bccs=(*recipients)
    return if self.mass_mail?
    @_bccs = recipients.flatten
  end

  def sender_with_params=(params_or_sender)
    case params_or_sender
    when Sender
      logger.debug {"==> Sender"}
      self.sender_without_params = params_or_sender
    when Party
      logger.debug {"==> Party"}
      self.build_sender(:party => params_or_sender)
    when Hash
      logger.debug {"==> Hash"}
      self.build_sender(params_or_sender)
    else
      raise ArgumentError, "Expected an instance of Sender, Party or Hash"
    end

    logger.debug {"==> sender: #{self.sender.inspect}"}
    self.sender.account = self.account

    returning(self.sender) do |sender|

      if sender.address.blank? then
        sender.send(:assign_default_address_and_name) unless sender.party_id.blank?
        raise ArgumentError, "Mail is being sent from nobody ?  Couldn't find any address to send from" if sender.address.blank?
      else
        route = self.account.email_contact_routes.find_by_address_and_routable_type(sender.address, "Party")
        sender.party = route.routable if route
      end
    end
  end
  alias_method_chain :sender=, :params

  def from
    addr = read_attribute(:from_address)
    addr.blank? ? "#{self.sender.name.to_forward_s} <#{self.sender.email}>" : addr
  end

  def from=(address)
    write_attribute(:from_address, :address)
  end

  # TODO remove this method as well?
  def build_email
    email = self.class.new(self.attributes)
    email.account = self.account
    email.released_at = email.scheduled_at = email.sent_at = nil
    email
  end

  def release(now=Time.now)
    self.released_at = now
    self.save
  end

  def release!(now=Time.now)
    self.released_at = now
    self.save!
  end

  def unrelease!
    self.released_at = nil
    self.save!
  end

  # TODO this method should send normal email, not sending out invidual email (mass email)
  # <b>WARNING: long operation</b>.
  # Sends this E-Mail to each recipient.
  # This is a NOP if the email is not ready or it is scheduled and its time
  # has not come to pass.
  def send!(now=Time.now)
    return unless self.ready?
    return if self.scheduled_at and self.scheduled_at > now
    return if self.sent?

    begin
      if self.mass_mail? then
        self.send_mass_mail!(now)
      else
        self.send_regular_mail!(now)
      end
    rescue Object, Exception
      self.reload

      # Try to send the mail again 30 minutes from now
      self.scheduled_at = 30.minutes.from_now
      self.error = $!.message
      self.backtrace = $!.backtrace.join("\n")
      self.error_count += 1
      self.save!

      raise "Could not send E-Mail #{self.id}: #{$!.message}" if self.error_count > 4
    end
  end

  def record_error(exception)
    self.error = exception.message
    self.error_count += 1
    self.backtrace = exception.backtrace
  end

  # Reschedule sending this mail at some later date
  def reschedule!(at=1.hour.from_now)
    self.scheduled_at = at
    self.save(false)
  end

  def error_limit_reached?
    self.error_count >= 1
  end

  def mark_bad_recipient!(recipient, reason)
    self.increment_bad_recipient_count
    self.released_at = nil
    self.save!
  end

  def return_non_delivery_to_sender!(reason)
    logger.debug {"==> return_non_delivery_to_sender!(#{self.id})"}
    self.class.transaction do
      self.released_at = nil
      self.save(false)

      non_delivery = self.account.emails.build(:subject => 'Undeliverable mail returned to sender',
          :about => self, :current_user => self.sender.party,
          :body => "The referenced E-Mail could not be sent for the following reason:\n  #{reason}\n\nSubject: #{self.subject}\n\nYou will need to release this E-Mail again after you correct the situation.  To release the mail, follow this link:\n  http://#{self.account.domain_name}/admin/emails/#{self.id}")
      non_delivery.tos.build(:party => self.sender.party, :extras => {}, :account =>  self.account,
          :name => self.sender.name, :address => self.sender.address)
      non_delivery.build_sender(:party => self.sender.party, :account => self.account,
        :address => self.sender.address, :name => self.sender.name)
      non_delivery.priority = 150
      non_delivery.save!
      non_delivery.release!
      non_delivery
    end
  end

  class << self
    def pluck_next_ready_mails
      with_scope(:find => {:conditions => "sent_at IS NULL AND released_at IS NOT NULL",
          :order => "scheduled_at, released_at"}) do
        self.find(:all, :conditions => ["scheduled_at IS NULL OR scheduled_at <= ?", Time.now.utc])
      end
    end

    def find_outbox
      self.find(:all, :conditions => 'released_at IS NOT NULL AND sent_at IS NULL AND received_at IS NULL',
                :order => 'released_at DESC')
    end

    def find_drafts
      self.find(:all, :order => "created_at DESC",
                :conditions => "released_at IS NULL AND sent_at IS NULL AND received_at IS NULL AND bad_recipient_count = 0")
    end
  end

  def main_identifier
    "#{self.subject} : #{self.status}"
  end

  def party_display_name
    self.sender ? self.sender.display_name : nil
  end

  def formatted_subject
    self.subject.blank? ? "(no subject)" : self.subject
  end

  def formatted_sender_name
    if self.sender && self.sender.party then
      return self.sender.party.name unless self.sender.party.name.blank?
    end

    "(unknown sender)"
  end

  def scheduled?
    self.scheduled_at
  end

  def received?
    self.status == :received
  end

  def sent?
    self.status == :sent
  end

  def ready?
    self.status == :ready
  end
  alias_method :released?, :ready?

  def draft?
    self.status == :draft
  end

  def unreleased?
    self.status == :unreleased
  end

  def status
    return :received if self.received_at
    return :sent if self.sent_at
    return :ready if (self.scheduled_at and self.scheduled_at <= Time.now and self.released_at) or (!self.scheduled_at and self.released_at)
    return :unreleased if self.scheduled_at and !self.released_at
    return :scheduled if self.scheduled_at
    :draft
  end

  def create_attachment!(params)
    return if params[:uploaded_data].size.zero?

    returning(self.attachments.create!(params)) do |attachment|
      (self.tos + self.ccs + self.bccs).each do |recipient|
        attachment.authorizations.create!(:name => recipient.party.name.to_s, :email => recipient.address)
      end

      attachment.authorizations.update_all("url_hash = '#{attachment.authorizations.first.url_hash}'")
    end
  end

  def clear_recipients_and_attachments
    %w(tos ccs bccs).each do |source|
      self.send(source).destroy_all
    end
    self.sender.destroy if self.sender
    self.attachments.destroy_all if self.attachments
    self.reload
  end

  def reply(current_user)
    prepare_reply(current_user) do |reply_email|
      # create recipient of the reply email: which is the sender of the initial email
      reply_email.tos.build(:address => self.sender.address, :name => self.sender.name,
          :account => reply_email.account, :party => self.sender.party)
      return reply_email
    end
  end

  def reply_to_all(current_user)
    prepare_reply(current_user) do |reply|
      reply.tos.build(:party => self.sender.party, :account => self.account, :email => reply,
          :address => self.sender.address, :name => self.sender.address)
      (self.tos + self.ccs).each do |recipient|
        #printf("%s: %s (%s)\n", recipient.address, recipient.name, (recipient.address == current_user.main_email.address).inspect)
        next if recipient.address == current_user.main_email.address
        reply.ccs.build(:name => recipient.name, :address => recipient.address, :email => reply,
            :account => self.account, :party => recipient.party)
      end
    end
  end

  def forward(current_user)
    prepare_forward(current_user) do |other|
    end
  end

  # Probably a better way to do this?
  def reply_forward_message_body
    message = []
    self.body.gsub("\r\n", "\n").each_line {|m| message << "> #{m.chomp}"}
    message.join("\n")
  end

  def self.find_bounced
    find(:all, :conditions => "about_id IS NOT NULL", :order => "sent_at DESC")
  end

  def belongs_to_party(party)
    temp = false
    %w(tos ccs bccs secondaries).each do |source|
      temp = temp || self.send(source).map(&:party_id).include?(party.id) unless self.send(source).blank?
      break if temp
    end
    return temp
  end

  def subject_template
    self.load_subject_template
  end

  def body_template
    self.load_body_template
  end

  protected
  def build_recipients(target, recipients)
    logger.debug {"==> \#build_recipients(#{target.inspect}, #{recipients.inspect})"}
    return if recipients.blank?
    recipients.flatten!
    recipients.collect! do |rcpt|
      next rcpt unless rcpt.respond_to?(:to_str)
      rcpt.split(/,|\n/)
    end
    recipients.flatten!
    
    parties, others = recipients.partition {|r| r.kind_of?(Party)}
    routes, others = others.partition {|r| r.kind_of?(EmailContactRoute)}

    routes.each do |route|
      self.send(target).create!(:account => self.account, :address => route.address, :recipient_builder_type => PartyListBuilder.name,
                                :recipient_builder_id => route.routable_id, :name => route.routable.name.to_s, :party => route.routable)
    end

    parties.each do |party|
      self.send(target).create!(:account => self.account, :address => party.main_email.address,
                                :recipient_builder_type => PartyListBuilder.name, :recipient_builder_id => party.id,
                                :name => party.name.to_s, :party => party)
    end

    others.map(&:strip).uniq.each do |email_plus_name|
      if email_plus_name =~ /\A\S+@\S+\.\S+\Z/i
        name, address = EmailContactRoute.decode_name_and_address(email_plus_name)
        unless address.blank?
          party = find_or_create_party_by_email_address(address)
          self.send(target).create!(:account => self.account, :address => address,
            :recipient_builder_type => PartyListBuilder.name, :recipient_builder_id => party.id,
            :name => name, :party => party)
        end
      elsif email_plus_name =~ /\Atag=(.+)\Z/i
        self.send(target).create!(:account => self.account, :tag_syntax => $1.strip,
            :recipient_builder_type => TagListBuilder.name)
      elsif email_plus_name =~ /\Asearch=(.+)\Z/i
        search = self.current_user.searches.find_by_name($1.strip)
        unless search.blank?
          self.send(target).create!(:account => self.account,
            :recipient_builder_id => search.id, :recipient_builder_type => SearchListBuilder.name)
        end
      elsif email_plus_name =~ /\Aaccount_owners(=(.+))?\Z/i
        self.send(target).create!(:account => self.account, :tag_syntax => $2.strip,
          :recipient_builder_id => nil, :recipient_builder_type => AccountOwnerListBuilder.name)
      else
        group = self.account.groups.find_by_name(email_plus_name)
        next if group.blank?
        self.send(target).create!(:account => self.account,
          :recipient_builder_id => group.id, :recipient_builder_type => GroupListBuilder.name)
      end
    end unless others.join().blank?
  end

  # helper method to takes care the creation of reply email object and its sender
  def prepare(current_user)
    raise "No recipients for E-Mail #{self.id}" if self.tos.empty? && self.bccs.empty? && self.ccs.empty?
    returning(current_user.account.emails.build(:current_user => current_user)) do |reply|
      reply.sender = current_user
      yield reply
    end
  end

  # helper method to generate subject and body of reply email
  # prepare_reply calls prepare method that creates the reply email object
  def prepare_reply(current_user, &block)
    prepare(current_user) do |reply_email|
      reply_email.subject = "Re: #{self.subject}"
      reply_email.body = <<EOF


On #{(self.received_at || Time.now).strftime('%Y-%m-%d %H:%M')}, #{self.sender.name} said:
#{reply_forward_message_body}
EOF
      yield(reply_email)
    end
  end

  def prepare_forward(current_user, &block)
    prepare(current_user) do |other|
      other.subject = "Fwd: #{self.subject}"
      other.body = <<EOF
Begin Forwarded Message:
> From: #{self.sender.to_formatted_s}
> Date: #{(self.received_at || Time.now).strftime('%Y-%m-%d %H:%M')}
> To: #{self.tos.to_formatted_s}
> Cc: #{self.ccs.to_formatted_s}
> Subject: #{self.subject}
>
#{reply_forward_message_body}
EOF

      yield(other)
    end
  end

  def sender_cant_be_blank
    self.errors.add_to_base("Please specify sender of the email") if self.sender.blank?
  end

  def find_or_create_party_by_email_address(email_address)
    email_contact_route = self.account.email_contact_routes.find_by_address_and_routable_type(email_address, "Party")
    return email_contact_route.routable if email_contact_route

    Party.transaction do
      returning self.account.parties.create! do |party|
        EmailContactRoute.create!(:address => email_address, :routable => party, :account => self.account)
      end
    end
  end

  # Sender is a type of recipient, so it is included here
  def recipients_as_text
    [self.sender, self.tos, self.ccs, self.bccs].flatten.map do |rcpt|
      [rcpt.name, rcpt.address]
    end
  end

  def dates_as_text
    returning [] do |dates|
      dates += [self.received_at.to_s(:iso), self.received_at.to_s(:short)] if self.received_at
      dates += [self.sent_at.to_s(:iso), self.sent_at.to_s(:short)] if self.sent_at
    end
  end

  def generate_mass_recipients
    self.class.transaction do
      logger.debug {"==> Removing existing mass recipients"}
      self.mass_recipients.delete_all
      logger.debug {"==> Processing #{self.tos.count} recipients"}
      self.tos.each do |recipient|
        recipient.email_addresses.each do |route|
          party = route.routable
          next unless party.kind_of?(Party)

          next if self.mass_recipients(true).map(&:address).index(route.address)

          attrs = {}
          attrs['from'] = recipient.email.sender.to_formatted_s
          attrs['now'] = Time.now
          attrs['year'] = attrs['now'].year
          attrs['month'] = attrs['now'].month
          attrs['month_name'] = FULL_MONTH_NAMES[attrs['month'] - 1]

          attrs['full_name'] = party.display_name
          attrs['company_name'] = party.company_name
          attrs['name'] = party.name.to_s
          attrs['name_only'] = party.name.to_s
          attrs['first_name'] = party.name.first
          attrs['last_name'] = party.name.last
          attrs['middle_name'] = party.name.middle
          attrs['email'] = party.main_email.address
          attrs['login_info'] = party.main_email.address
          attrs['uuid'] = party.uuid

          if address = party.main_address then
            attrs['line1'] = address.line1
            attrs['line2'] = address.line2
            attrs['city'] = address.city
            attrs['state'] = address.state
            attrs['zip'] = address.zip
            attrs['country'] = address.country
          end
          
          if self.body =~ /\{\{\s*randomize_password_if_none\s*\}\}/ && party.password_hash.blank? then
            pw = party.randomize_password!
            unless pw.blank?
              party.confirm!
              attrs['randomize_password_if_none'] = "Password: #{pw}"
            end
          end
          
          # TODO do something about reset password email
          if recipient.email.generate_password then
            attrs['new_password'] = recipient.party.randomize_password!
          end

          self.mass_recipients.create!(:name => route.fullname, :address => route.address, :account => self.account,
              :party_id => route.routable_id, :extras => attrs)
        end
      end

      logger.debug {"==> Done generating mass recipients"}
    end
  end

  def make_recipient(recipient)
    logger.debug {"==> Building for #{recipient.inspect}"}
    send_to = self.tos.build(:account => self.account, :email => self)

    case recipient
    when Party
      send_to.update_attributes(:party => recipient)

    when /\Atag\s*[=:]\s*(.+)\Z/i
      send_to.update_attributes(:tag_syntax => $1.strip,
                                :recipient_builder_type => TagListBuilder.name)

    when /\Asearch[=:](.+)\Z/i
      search = self.current_user.searches.find_by_name($1)
      raise ActiveRecord::RecordNotFound, "Could not find search named #{$1.inspect}" if search.blank?
      send_to.update_attributes(:recipient_builder_id => search.id,
                                :recipient_builder_type => SearchListBuilder.name)

    when /\Aaccount_owners(=(.+))?\Z/i
      send_to.update_attributes(:tag_syntax => $1,
                                :recipient_builder_type => AccountOwnerListBuilder.name)

    when /\A(\w|\s)*\S+@\S+\.\S+\Z/i
      valid_email = recipient.match(EmailContactRoute::ValidAddressRegexp)
      if valid_email
        recipient = valid_email[0]
      else
        return
      end
      party = find_or_create_party_by_email_address(recipient)
      send_to.update_attributes(:address => recipient,
                                :recipient_builder_type => PartyListBuilder.name, :party => party)

    else
      group = self.account.groups.find_by_name(recipient)
      raise ActiveRecord::RecordNotFound, "Could not find group named #{recipient.inspect}" if group.blank?
      send_to.update_attributes(:recipient_builder_id => group.id,
                                :recipient_builder_type => GroupListBuilder.name)
    end
  end

  def ccs_and_bccs_is_empty
    return unless self.mass_mail?
    self.errors.add(:ccs, "must be blank") unless (@_ccs.blank? && self.ccs.blank?)
    self.errors.add(:bccs, "must be blank") unless (@_bccs.blank? && self.bccs.blank?)
  end

  # sends email to each MassRecipient
  def send_mass_mail!(now=Time.now)
    logger.debug {"==> Generating mass recipients for #{self.id}"}
    self.generate_mass_recipients if self.mass_recipients.empty?
    logger.debug {"==> There are #{self.mass_recipients.unsent_count} unsent recipients out of #{self.mass_recipients.count}"}
    self.class.transaction do
      self.mass_recipients.unsent.in_groups_of(100, false) do |group|
        priority = group.compact.size <= 10 ? 100 : 250
        MethodCallbackFuture.create!(:models => group, :method => :send!, :system => true, :account => self.account, :priority => priority)
      end

      self.tag_list = self.tag_list << ' sent'
      self.sent_at = Time.now.utc
      self.save!
    end
  end

  def send_regular_mail!(now)
    begin
      recipients = [self.tos, self.ccs, self.bccs]
      raise NoRecipientsError if recipients.map(&:count).sum.zero?
      MassMailer.deliver_mailing(self)
      self.update_attribute(:sent_at, now)
    rescue NoRecipientsError
      logger.warn {$!}
      self.record_error($!)
      self.return_non_delivery_to_sender!("No recipients")

    rescue Net::SMTPError
      self.record_error($!) # No save, as the next two calls save the record

      if self.error_limit_reached? then
        self.return_non_delivery_to_sender!("Exceeded retry count (#{self.error_count} times)")
      else
        self.reschedule!(1.hour.from_now)
      end
    end
  end

  def build_tos
    recipients = @_tos
    @_tos = nil
    return unless recipients
    if self.mass_mail? then
      logger.debug {"==> mass email"}
      self.tos.clear
      return if recipients.blank? || recipients.all?(&:blank?)
      recipients.collect! do |rcpt|
        next rcpt unless rcpt.respond_to?(:to_str)
        rcpt.to_str.split(/,|\n/).map(&:strip).uniq
      end

      logger.debug {"==> recipients: #{recipients.inspect}"}
      recipients.flatten.each do |rcpt|
        make_recipient(rcpt)
      end
    else
      logger.debug {"==> regular mail"}
      build_recipients(:tos, recipients)
    end
  end
  
  def build_ccs
    build_recipients(:ccs, @_ccs)
    @_ccs = nil
  end
  
  def build_bccs
    build_recipients(:bccs, @_bccs)
    @_bccs = nil
  end

  def verify_liquid_templates_syntax
    begin
      @liquid_subject_template = Liquid::Template.parse(self.subject)
    rescue SyntaxError
      self.errors.add(:subject, "is invalid: #{$!.message}")
    end

    begin
      @liquid_body_template = Liquid::Template.parse(self.body)
    rescue SyntaxError
      self.errors.add(:body, "is invalid: #{$!.message}")
    end
  end

  def dump_liquid_templates
    self.parsed_subject = Marshal.dump(@liquid_subject_template)
    self.parsed_body = Marshal.dump(@liquid_body_template)
  end

  def load_subject_template
    @liquid_subject_template ||= Marshal.load(self.parsed_subject)
  end

  def load_body_template
    @liquid_body_template ||= Marshal.load(self.parsed_body)
  end

  def increment_bad_recipient_count
    self.class.connection.execute("UPDATE emails SET bad_recipient_count = bad_recipient_count + 1 WHERE id=#{self.id}")
  end  
end
