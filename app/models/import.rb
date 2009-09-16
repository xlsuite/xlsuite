#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "fastercsv"

class Import < ActiveRecord::Base
  belongs_to :account
  belongs_to :party
  
  validates_presence_of :party_id 
  
  serialize :import_errors 
  serialize :imported_lines
  serialize :mappings
  
  attr_protected :mappings
  
  before_create :set_state_to_new
  
  def first_x_lines(x)
    index = 0
    array = []
    return array unless self.csv
    CSV::Reader.parse(self.csv) do |row|
      index += 1
      break if index > x
      array << row
    end
    return array
    rescue
      return -1
  end
  
  def has_blank_mappings?
    return true if self.mappings.nil? || self.mappings[:map].blank?
    array = self.mappings[:map].reject{|e| e.nil?}
    return true if array.blank?
    return false
  end
  
  def file=(file)
    self.filename = file.original_filename
    self.csv = file.read
  end
  
  def get_line1(address_array)
    address_array.length > 2 ? (address_array.first || "") : ""
  end
  
  def get_city(address_array)
    address_array.shift if address_array.length > 2
    address_array.first || ""
  end
  
  def get_state(address_array)
    return (address_array.first || "") if address_array.length <= 1
    last_line = address_array.last
    last_line.split(' ').first || ""
  end
  
  def get_zip(address_array)
    address_array.last =~ /\d{5}/
    return $1 ? $1 : ''
  end
  
  def get_postal(address_array)
    address_array.last =~ /[^\d\s]\d[^\d\s]\s\d[^\d\s]\d/
    return $1 ? $1 : ''
  end
  
  def go!      
    begin
      self.update_attribute(:state, "Importing...")
      
      mapper             = Mapper.new(:account_id => self.account.id)
      mapper.mappings    = self.mappings
      
      header_lines_count = self.mappings[:header_lines_count].to_i
      tag_list_field     = self.mappings[:tag_list]
      create_profile     = self.mappings[:create_profile]
      group_name         = self.mappings[:group]
      group              = self.account.groups.find_by_name(group_name)
      available_on_domain_id = self.mappings[:domain_id]
      action_handler_id = self.mappings[:action_handler_id]
      
      self.import_errors, self.imported_lines = [], []
      FasterCSV.parse(self.csv)[header_lines_count + self.imported_rows_count .. -1].in_groups_of(100, false) do |rows|
        Party.transaction do
          rows.each do |row|
            raise "aborting" if row[0] == "c"
            import_row(row, mapper, tag_list_field, create_profile, group, available_on_domain_id, action_handler_id)
          end
          
          # Prepare for next round, in case of a crash
          self.update_attribute(:imported_rows_count, self.imported_rows_count + rows.length)
        end
      end
      
      raise ImportAbortedByErrors if !self.import_errors.blank? && !self.force?
      self.update_attribute(:state, "Imported")
    rescue ImportAbortedByErrors
      # Don't try to import again
      self.update_attribute("state", "Failed")
    rescue InvalidScrapeUrl
      self.update_attribute("state", "Invalid URL")
    rescue ScrapeAbortedByErrors
      self.update_attribute("state", "Scrape Failed")
    end
  end
  
  def total_rows_count
    return 0 if self.csv.blank?
    @total_rows_count ||= FasterCSV.parse(self.csv).length - self.mappings[:header_lines_count].to_i
  end
  
  def import_row(row, mapper, tag_list_field, create_profile, group, available_on_domain_id, action_handler_id)
    party = mapper.to_object(row)
    return party.destroy if party.email_addresses.map(&:email_address).blank? && self.mappings[:exclude_no_email]
    
    initial_party_id = party.id
    party = resolve_conflicts(party)
    resolved_party_id = party.id
    party.tag_list = party.tag_list << " #{tag_list_field}"
    
    party.created_by = self.party
    party.groups << group if group && !party.member_of?(group)
    
    if create_profile then
      unless party.profile
        profile = party.to_new_profile
        profile.save!
        party.profile = profile
      end
      if party.biography 
        profile.about = party.biography
        profile.save!
      end
      party.save!
      party.reload.copy_contact_routes_to_profile!
    else
      party.save!
    end

    if !available_on_domain_id.blank?
      available_on_domain_id = available_on_domain_id.to_i
      DomainAvailableItem.create(:account_id => party.account_id, :domain_id => available_on_domain_id, :item_type => party.class.name, :item_id => party.id)

      if !action_handler_id.blank?
        action_handler_id = action_handler_id.to_i
        ActionHandlerMembership.create(:party => party, :domain_id => available_on_domain_id,
          :action_handler => party.account.action_handlers.find(action_handler_id))
      end
    end
    
    
    self.imported_lines << true
  rescue ActiveRecord::RecordInvalid
    party.destroy if party && (initial_party_id == resolved_party_id)
    self.import_errors << [row, $!.record.errors.full_messages]
    self.imported_lines << false
  end
  
  def resolve_conflicts(new_party)
    addresses = new_party.email_addresses.map(&:email_address)
    
    #RAILS_DEFAULT_LOGGER.debug("import resolve_conflicts addresses = #{addresses.inspect}")
    routes = self.account.email_contact_routes.find(:all, :conditions => {:email_address, addresses})
    routes.reject!{|r|r.routable_type != "Party"}
    logger.debug("^^^#{routes.inspect}")
    case routes.map(&:routable_id).uniq.size
      when 0
      # None match, return the new party
      #RAILS_DEFAULT_LOGGER.debug("I am a new party")
      new_party
      when 1
      # Party already on file, update instead of create
      #RAILS_DEFAULT_LOGGER.debug("Existing party found")
      party = routes.first.routable
      new_party.copy_to(party)
      new_party.destroy
      party
    else
      # Multiple contacts match!
      # Raise an exception that logs the error
      raise MultipleContactsException.new("Duplicate contacts found while importing")
    end
  end
  
  protected
  def set_state_to_new
    self.state = "New" unless self.state
  end
end

class MultipleContactsException < StandardError; end;
class ImportAbortedByErrors < StandardError; end;
class ScrapeAbortedByErrors < StandardError; end;
class InvalidScrapeUrl < StandardError; end;
