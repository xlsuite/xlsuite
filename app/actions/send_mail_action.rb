#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class SendMailAction < Action
  attr_accessor :template_id, :sender_id, :mail_type

  def run_against(*args)
    options = args.last.kind_of?(Hash) ? args.pop : Hash.new
    recipients = args.flatten.compact
    return if recipients.empty?
    returning(Email.create!(:subject => self.template.subject, :body => self.template.body,
        :mail_type => self.mail_type, :mass_mail => false,
        :sender => self.sender, :tos => recipients, :account => options[:account])) do |email|
      email.release!
    end
  end

  def sender
    @sender ||= (self.sender_id ? Party.find(self.sender_id) : nil rescue nil)
  end

  def sender=(party)
    self.sender_id = party.id
    @sender = party
  end

  def template
    @template ||= (self.template_id ? Template.find(self.template_id) : nil rescue nil)
  end

  def template=(template)
    self.template_id = template.id
    @template = template
  end

  def description
    "Send mail template \"#{self.template.label rescue nil}\" from \"#{self.sender.display_name rescue nil}\""
  end
  
  def duplicate(account, options={})
    action = self.class.new
    if self.template
      target_template = account.templates.find_by_label(self.template.label)
      if options[:create_dependencies]
        target_template ||= account.templates.create!(self.template.attributes_for_copy_to(account))
      end
      action.template_id = target_template.id if target_template
    end
    action.sender_id = account.owner.id
    action.mail_type = self.mail_type
    action
  end
  
  class << self
    def parameters
      [ {:sender => {:type => :parties, :field => "selection", :store => {:helper => "party_auto_complete_store"}, :mode => "remote", :width => 350, :empty_text => "Autocomplete field, please start typing", :default_value => "@action.sender ? @action.sender.display_name : ''"}}, 
        {:template => {:type => :templates, :field => "selection", :store => "current_account.templates.find_all_accessible_by(current_user, :order => 'label ASC').map{|t|[t.label, t.id]}"}}, 
        {:mail_type => {:type => :string, :field => "selection", :store => "Email::ValidMailTypes.map{|e|[e, e]}"}} ]
    end
  end
end
