#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class SendMassMailAction < SendMailAction
  attr_accessor :template_id, :sender_id, :domain_id, :mail_type, :return_to_url, :tags_to_remove, :opt_out_url

  def run_against(*args)
    options = args.last.kind_of?(Hash) ? args.pop : Hash.new
    recipients = args.flatten.compact
    return if recipients.empty?
    returning(Email.create!(:subject => self.template.subject, :body => self.template_body,
        :mail_type => self.mail_type, :mass_mail => true, :domain => self.domain,
        :sender => self.sender, :tos => recipients, :account => options[:account],
        :return_to_url => self.return_to_url.blank? ? '/admin/opt-out/unsubscribed' : self.return_to_url, 
        :tags_to_remove => self.tags_to_remove, :opt_out_url => self.opt_out_url.blank? ? '/admin/opt-out' : self.opt_out_url)) do |email|
      email.release!
      
      # building inactive recipients TagListBuilder and GroupListBuilder for the email
      Step.find(options[:step_id]).lines.each do |line|
        next if line.excluded? || line.operator != "="
        case line.field
        when /^tagged/i
          line.value.split(",").map(&:strip).each do |tag|
            recipient = email.tos.build(:account => options[:account], :email => email, :inactive => true)
            recipient.update_attributes(:tag_syntax => tag,
                                    :recipient_builder_type => TagListBuilder.name)
          end
        when /^group_label$/i
          group = options[:account].groups.find_by_label(line.value)
          next unless group   
          recipient = email.tos.build(:account => options[:account], :email => email, :inactive => true)
          recipient.update_attributes(:recipient_builder_id => group.id,
                                  :recipient_builder_type => GroupListBuilder.name)                        
        end
      end
      
    end
  end

  def domain
    @domain = (self.domain_id ? Domain.find(self.domain_id) : nil rescue nil)
  end

  def domain=(domain)
    self.domain_id = domain.id
    @domain = domain
  end

  def description
    "Send mass mail template \"#{self.template.label rescue nil}\" from \"#{self.sender.display_name rescue nil}\""
  end
  
  def template_body
    t_body = self.template.body || ""
    unless t_body =~ /\{%\s*opt_out_url\s*%\}/
      t_body = t_body + "<br /><p>If you feel you have received this email in error, or would like to remove yourself from future mailings, simply opt out here : {% opt_out_url %}. Thank you.</p>"
    end
    t_body
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
    action.domain = account.domains.first
    %w(mail_type return_to_url tags_to_remove opt_out_url).each do |attr|
      action.send("#{attr}=", self.send(attr)) if action.respond_to?("#{attr}=".to_sym)
    end
    action
  end

  class << self
    def parameters
      super +
        [{:domain => {:type => :domains, :field => "selection", :store => "current_account.domains.find(:all, :order => 'name ASC').map {|d| [d.name, d.id]}"}},
        {:opt_out_url => {:type => :string, :label => "Set unscubscribe page URL", :field => "selection", :store => "current_account.pages.find(:all, :order => 'fullslug ASC').map{|p|[p.fullslug, p.fullslug]}.unshift(['/admin/opt-out', '/admin/opt-out'], ['/admin/opt-out/unsubscribed', '/admin/opt-out/unsubscribed'])", :default_value => "@action.opt_out_url ? @action.opt_out_url : '/admin/opt-out'"}},
        {:return_to_url => {:type => :string, :label => "Set confirmation page URL", :field => "selection", :store => "current_account.pages.find(:all, :order => 'fullslug ASC').map{|p|[p.fullslug, p.fullslug]}.unshift(['/admin/opt-out', '/admin/opt-out'], ['/admin/opt-out/unsubscribed', '/admin/opt-out/unsubscribed'])", :default_value => "@action.return_to_url ? @action.return_to_url : '/admin/opt-out/unsubscribed'"}},
        {:tags_to_remove => {:type => :string, :label => "Remove tag(s) from unsubscriber", :field => "selection", :store => "current_account.parties.tags.map{|t|[t.name, t.name]}"}}]
    end
  end
end
