#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Search < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id
  before_validation {|p| p.account = p.party.account if p.party }

  belongs_to :party
  has_many :search_lines, :dependent => :destroy, :order => 'priority ASC'
  has_many :sort_lines, :dependent => :destroy, :order => 'priority ASC'
  validates_presence_of :name
  
  def main_identifier
    "#{self.name} : #{self.description}"
  end

  def perform
    search_params = self.search_lines.map(&:to_hash) 
    sort_params = self.sort_lines.map(&:to_hash)
    sorted_bys, search_results = AdvancedSearch::perform_search(search_params, sort_params, :account => self.party.account)        
    [sorted_bys, search_results]
  end
  
protected
  def party_display_name
    self.party ? self.party.display_name : nil
  end      
end
