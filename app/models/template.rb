#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Template < ActiveRecord::Base
  include XlSuite::AccessRestrictions
  
  belongs_to :account
  validates_presence_of :account_id
  
  belongs_to :party
  validates_presence_of :party_id
 
  validates_presence_of :label
  validates_uniqueness_of :label, :scope => :account_id
  
  acts_as_taggable
  acts_as_fulltext %w(label description subject body tags_as_text party_as_text)
  
  
  def self.find_readable_by(party, query_params, search_options)
    group_ids = party.groups.find(:all, :select => "groups.id").map(&:id)
    conditions = "groups.id IS NULL"
    conditions << " OR groups.id IN (#{group_ids.join(',')})" unless group_ids.blank?
    template_ids = self.find(:all, :select => "#{self.table_name}.id",
      :joins => [%Q`LEFT JOIN authorizations ON authorizations.object_type="#{self.name}" AND authorizations.object_id=#{self.table_name}.#{self.primary_key}`, 
          %Q`LEFT JOIN groups ON groups.id=authorizations.group_id`].join(" "), 
      :conditions => conditions ).map(&:id)
    return [] if template_ids.blank?
    self.search(query_params, search_options.merge(:conditions => "#{self.table_name}.#{self.primary_key} IN (#{template_ids.join(",")})"))
  end
  
  def self.count_readable_by(party, query_params)
    group_ids = party.groups.find(:all, :select => "groups.id").map(&:id)
    conditions = "groups.id IS NULL"
    conditions << " OR groups.id IN (#{group_ids.join(',')})" unless group_ids.blank?
    template_ids = self.find(:all, :select => "#{self.table_name}.id",
      :joins => [%Q`LEFT JOIN authorizations ON authorizations.object_type="#{self.name}" AND authorizations.object_id=#{self.table_name}.#{self.primary_key}`, 
          %Q`LEFT JOIN groups ON groups.id=authorizations.group_id`].join(" "), 
      :conditions => conditions).map(&:id)
    count_options = nil
    return 0 if template_ids.blank?
    if query_params.blank?
      count_options = {:conditions => "#{self.table_name}.#{self.primary_key} IN (#{template_ids.join(",")})"}
    else
      count_options = {:conditions => "subject_type='#{self.name}' AND subject_id IN (#{template_ids.join(",")})"}
    end
    self.count_results(query_params, count_options)
  end
  
  def self.find_all_accessible_by(current_user, qoptions={})
    templates = []
    current_user.account.templates.find(:all, qoptions).each do |template|
      templates << template if template.writeable_by?(current_user)
    end
    templates
  end
  
  def tags_as_text
    self.tags.map(&:name)
  end
  
  def party_as_text
    self.party ? self.party.name.to_s : ""
  end
  
  def attributes_for_copy_to(account)
    self.attributes.dup.symbolize_keys.merge(:account_id => account.id, :party_id => account.owner ? account.owner.id : nil, :tag_list => self.tag_list)
  end
end
