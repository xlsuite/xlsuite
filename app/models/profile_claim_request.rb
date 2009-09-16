#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ProfileClaimRequest < ProfileRequest
  
  def approve!
    ProfileAddRequest.transaction do
      self.copy_request_to_profile! 
      self.approved_at = Time.now
      self.save!
    end
  end
  
  def copy_request_to_profile!
    @profile = self.profile
    @party =  @profile.party
    %w( first_name middle_name last_name company_name position honorific).each do |column|
      @profile.send(column+"=", self.send(column))
      @party.send(column+"=", self.send(column))
    end
    
    @profile.avatar_id = self.avatar_id unless self.avatar_id.blank?
    @profile.tag_list = @profile.tag_list + "," + self.tag_list
    @party.tag_list = @party.tag_list + "," + self.tag_list
    
    # Adding domain membership of action handlers to the attached profile
    if !self.action_handler_labels.blank? && !self.domain_id.blank?
      @profile.action_handler_labels = self.action_handler_labels
      @profile.action_handler_domain_id = self.domain_id
    end
    
    @party.replace_domains = self.available_on_domains.map(&:name).join(",")
    
    @profile.info = self.info
    @profile.owner = nil
    @profile.claimed_at = Time.now
    @profile.save!
    @party.save!
    
    if self.group_ids
      groups = self.account.groups.all(:conditions => ["id IN (?)", self.group_ids.split(",")])
      @party.groups << groups unless groups.empty?
    end
    
    %w(email_addresses links phones addresses).each do |cr_type|
      @profile.send(cr_type).each do |cr|
        cr.destroy
      end
      @party.send(cr_type).each do |cr|
        cr.destroy
      end
    end
    self.copy_contact_routes_to_party!(@party)
    @party.reload
    @party.copy_contact_routes_to_profile!
    
    self.deliver_signup_confirmation_email
  end
  
  def deliver_signup_confirmation_email
    party = self.profile.party
    return unless party
    party.reload.deliver_signup_confirmation_email(:route => party.main_email(true),
              :confirmation_url => self.confirmation_url,
              :confirmation_token => party.confirmation_token)
  end
end
