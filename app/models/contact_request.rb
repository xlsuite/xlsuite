#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ContactRequest < ActiveRecord::Base
  validates_presence_of :account_id
  belongs_to :account
  belongs_to :domain
  
  belongs_to :affiliate

  auto_scope \
      :completed => {
          :find => {:conditions => ["completed_at < ?", proc {Time.now}]},
          :create => {:completed_at => proc {Time.now}}},
      :incomplete => {
          :find => {:conditions => ["completed_at IS NULL"]},
          :create => {:completed_at => nil}}

  belongs_to :party
  has_and_belongs_to_many :recipients, :class_name => "Party", :join_table => "contact_request_recipients"
  acts_as_reportable \
      :columns => %w(name email phone subject body spaminess referrer_url params approved_at created_at updated_at completed_at)
  
  before_save :generate_subject
  validates_each :name do |record, attr|
    record.errors.add_on_blank(attr) if record.party.blank?
  end

  validates_format_of :email, :with => %r{[A-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]{2,}}i, :allow_nil => true

  acts_as_taggable
  acts_as_fulltext %w(name email phone subject tag_list body subject)

  serialize :params, Hash

  def to_liquid
    ContactRequestDrop.new(self)
  end
  
  def params
    read_attribute(:params) || write_attribute(:params, Hash.new)
  end
  
  def create_party
    return if self.params.blank?
    return unless self.add_party_to_database
    
    params = self.params
    params.stringify_keys!
    
    t_party = nil
    # find user by email
    # NOTE: params[:email_address] has to be in the form of {"Main" => {:email_address => "test@test.com"}}
    if params.has_key?("email_address") then
      params["email_address"].each do |name, attrs|
        route = self.account.email_contact_routes.find_by_address_and_routable_type(attrs[:email_address], "Party")
        next unless route
        next unless route.routable_type =~ /party/i
        t_party = route.routable
        break
      end
    end
    
    if t_party 
      # update blank attributes of parties if party params is specified
      if params["party"]
          if params["party"][:tag_list]
            t_party.tag_list = t_party.tag_list << %Q!, #{params["party"].delete(:tag_list)}!
          end
          if params["party"][:group_ids]
            self.account.groups.find(params["party"][:group_ids]).to_a.each do |g|
              t_party.groups << g unless t_party.groups.include?(g)
            end
            t_party.update_effective_permissions = true
            params["party"].delete(:group_ids)
          end
        params["party"].each do |key, value|
          t_party.send("#{key}=".to_sym, value) if t_party.send(key.to_sym).blank? rescue next 
        end
      end
    else
      new_party_group_ids = params["party"].delete(:group_ids)
      t_party = self.account.parties.build(params["party"])
    end
    errors = self.save_contact_routes_to_party(t_party, params)
    if new_party_group_ids
      self.account.groups.find(new_party_group_ids).to_a.each do |g|
        t_party.groups << g unless t_party.groups.include?(g)
      end
      t_party.update_effective_permissions = true
    end
    if errors.blank?
      self.party = t_party.reload
      self.save!
    else
      return errors
    end
  end
  
  def save_contact_routes_to_party(party, params)
    valid_contact_routes = []
    error_messages = []
    %w(email_address address phone link).each do |type|
      next unless params[type]
      params[type].each do |name, attrs|
        route = party.send(type.pluralize).find_or_initialize_by_name(name)
        # do not update Main email address if it's not blank
        if route.class.name == "EmailContactRoute" && route.email_address.blank? && route.name =~ /main/i
          route.attributes = attrs
        elsif (route.class.name != "EmailContactRoute") || (route.class.name == "EmailContactRoute" && route.name !~ /main/i )
          route.attributes = attrs
        end
        route_errors = []
        case type
          when "email_address"
            route.save
            route_errors << route.errors.on(:email_address) unless route.errors.on(:email_address).nil?
            route_errors = route_errors.flatten.map {|x| "Email address " + x.to_s}
            error_messages += route_errors
            valid_contact_routes << route if route_errors.blank? 
          when "address"
            if (attrs.values.delete_if {|e| e.to_s.blank?}).blank?
              error_messages << "All address fields are blank. Please fill at least one field"
            else
              valid_contact_routes << route
            end
          when "phone"
            route.save
            route_errors << route.errors.on(:number) unless route.errors.on(:number).nil?
            route_errors = route_errors.flatten.map {|x| "Phone number " + x.to_s}
            error_messages += route_errors
            valid_contact_routes << route if route_errors.blank? 
          when "link"
            route.save
            route_errors << route.errors.on(:url) unless route.errors.on(:url).nil?
            route_errors = route_errors.flatten.map {|x| "Link url " + x.to_s}
            error_messages += route_errors
            valid_contact_routes << route if route_errors.blank? 
          else
        end
      end
    end
    if valid_contact_routes.blank?
      error_messages << "No valid contact route specified"
    else
      error_messages.clear
    end

    if !valid_contact_routes.blank?
      party.save!

      for cr in valid_contact_routes
        cr.routable = party
        cr.save!
      end
    end
    error_messages
  end
  
  def build_body(params, content)
    email_addresses = params[:email_address].values.map{|a| a[:email_address]}.join(", ") rescue ""
    phone_numbers = params[:phone].values.map{|a| a[:number]}.join(", ") rescue ""
    party_params = params[:party]
    addresses = params[:address]
    time_to_call = params[:contact_request][:time_to_call] if params[:contact_request]
    
    out = %Q`
    Contact Information<br />
    `
    out << "Email Address: #{ email_addresses }<br />\n"
    out << "Company Name: #{ party_params[:company_name] }<br />\n" if party_params && party_params.has_key?(:company_name)
    out << "First Name: #{ party_params[:first_name]}<br />\n"  if party_params && party_params.has_key?(:first_name) 
    out << "Last Name: #{ party_params[:last_name]}<br />\n" if party_params && party_params.has_key?(:last_name) 
    out << "Name: #{ party_params[:full_name]}<br />\n" if party_params && party_params.has_key?(:full_name) 
    out << "Phone Number: #{ phone_numbers }<br />\n" if params.has_key?(:phone)

    if addresses
      addresses.each do |name, address|
        out << "#{name.titleize} Address: <br />"
        if address[:line1]
          out << "&nbsp;&nbsp;Line1: #{ address[:line1] }<br />"
        end
        if address[:line2]
          out << "&nbsp;&nbsp;Line2: #{ address[:line2] }<br />"
        end
        if address[:city]
          out << "&nbsp;&nbsp;City: #{ address[:city]}<br />"
        end
        if address[:state]
          out << "&nbsp;&nbsp;State: #{ address[:state]}<br />"
        end
        if address[:country]
          out << "&nbsp;&nbsp;Country: #{ address[:country]}<br />"
        end
        if address[:zip]
          out << "&nbsp;&nbsp;Postal code: #{ address[:zip]}<br />"
        end
      end
    end
    
    if time_to_call 
      out << "Time to call: #{ time_to_call }<br />"
    end
    
    out << "Body: <br />#{content}<br />"
    out.gsub(/\r\n/, "<br />")
    self.body = out
  end
  
  def contains_blacklist_words
    return false unless self.domain
    blacklist_words = self.domain.get_config("blacklist_words")
    blacklist_words_array = blacklist_words.split(',').map(&:strip).reject(&:blank?)
    return false if blacklist_words_array.join("").blank?
    blacklist_regex = Regexp.new("(#{blacklist_words_array.join('|')})", true)
    %w(name email body subject).each do |column|
      return true if self.send(column) =~ blacklist_regex
    end
    false
  end
  
  def do_spam_check!
    response = defensio.ham?(
      self.request_ip, self.created_at, self.name, "comment", {:body => self.body, :email => self.email}
    )
    if response[:status] == "fail"
      raise response[:message]
    else
      (response[:spam] || self.contains_blacklist_words) ? mark_as_spam!(response[:spaminess], response[:signature]) : mark_as_ham!(response[:spaminess], response[:signature])
      self.save!
    end
  end

  def mark_as_ham!(spaminess, signature)
    self.approved_at = Time.now.utc
    self.spaminess = spaminess
    self.defensio_signature = signature
  end

  def mark_as_spam!(spaminess, signature)
    self.approved_at = nil
    self.spaminess = spaminess
    self.defensio_signature = signature
  end

  def confirm_as_ham!
    self.update_attribute("approved_at", Time.now.utc)
    self.create_party unless self.party
    defensio.mark_as_ham(self)
  end

  def confirm_as_spam!
    self.update_attribute("approved_at", nil)
    defensio.mark_as_spam(self)
  end

  def complete!
    self.completed_at = Time.now
    self.save!
  end

  def completed?
    self.completed_at
  end
  
  def main_identifier
    "#{self.name} : #{self.subject}"
  end

  protected
  def defensio
    @defensio ||= Mephisto::SpamDetectionEngines::DefensioEngine::new
  end  
  
  def generate_subject
    self.subject = self.subject.blank? ? (self.body.blank? ? "Contact Request" : self.body[0...40]+"...") : self.subject
  end
end
