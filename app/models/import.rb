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
  
  def scrape!
    
    url = self.filename.gsub("http://", "").split('/')
    
    case url.first
      when /www.yellowpages\.com/i
        do_yellowpages_com_scrape(url)
      when /yellowpages\.ca/i
        do_yellowpages_ca_scrape(url)
      else
        raise InvalidScrapeUrl
      end
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
  
  def do_yellowpages_ca_scrape(url)
    html = nil
    
    entry = Scraper.define do
      process "td[width='100%'] a span", :company => :text
      process "span.phoneNumber span.hiLiteThis", :number => :text
      process "td[width='100%'] a#mapLink0", :url => :text
      process "td[width='100%'] a[name*='lid=email']", :email => :text
      process "td.icon table tr td img:not([src='/images/th_frame.gif'])" , :image => "@src"
      process "span.address", :address => :text
      result :company, :number, :url, :email, :image, :address
    end
    
    page = Scraper.define do
      array :entries
      process "div.listing", :entries => entry
      result :entries
    end
    
    paginator = Scraper.define do
      process "td.yellowHead td.alignRight a:last-child", :url => "@href"
      result :url
    end
    
    root_url = url.shift

    csv = ""
    
    begin
      while !url.blank?
      logger.debug('/'+url.join('/'))
        Net::HTTP.start(root_url) {|http|
          http.request_get('/'+url.join('/')) {|res|
            html = res.read_body
          }
        }
        
        entries = page.scrape(html)
        entries.each do |entry|
          next if self.mappings[:exclude_no_email] && (entry.email.blank? || entry.email.gsub(",", "").blank?)
          address_array = entry.address.to_s.split(',')
          address_array = [""] if address_array.empty?
          csv << "#{entry.company.gsub(",", "") if entry.company}, #{entry.email.gsub(",", "") if entry.email}, #{entry.number.gsub(",", "") if entry.number}, #{entry.url.gsub(",", "") if entry.url}, "
          csv << "#{get_line1(address_array).strip}, #{get_city(address_array).strip}, #{get_state(address_array).strip}, #{get_postal(address_array).strip}, #{entry.image.strip if entry.image}"
          csv << "\n"
        end unless entries.blank?
        self.last_scraped_url = url.unshift(root_url).join("/")
        
        url = paginator.scrape(html)
        logger.debug("^^^page: #{url.inspect}")
        url = url.split('/').reject(&:blank?) unless url.blank?
      end
        
      self.csv = csv
      self.save!
    rescue      
      self.save
      self.update_attribute("import_errors", $!.message + $!.backtrace.join("\n"))
      raise ScrapeAbortedByErrors
    end
  end
  
  def do_yellowpages_com_scrape(url)
    html = nil
    
    entry = Scraper.define do
      process "h2 a", :company => :text, :url => "@href"
      process "a.email", :email => "@href"
      process "li.number", :number => :text
      process "li a.web", :url => "@href"
      process "h2+p", :address => :element
      result :email, :company, :url, :number, :address
    end
    
    page = Scraper.define do
      array :entries
      process "div#mid-column li.listing", :entries => entry
      result :entries
    end
    
    paginator = Scraper.define do
      process "div#toolbar-btm li.next a", :url => "@href"
      result :url
    end
    
    root_url = url.shift

    csv = ""
    
    begin
      while !url.blank?
        logger.debug('/'+url.join('/'))
        Net::HTTP.start(root_url) {|http|
          http.request_get('/'+url.join('/')) {|res|
            html = res.read_body
            logger.debug("^^^#{url}")
          }
        }
        
        entries = page.scrape(html)
        entries.each do |entry|
          next if self.mappings[:exclude_no_email] && (entry.email.blank? || entry.email.gsub('mailto:', '').gsub(",", "").blank?)
          address_array = entry.address.to_s.gsub(/<.*?>/, "").split(/\n|,/)
          csv << "#{(entry.company).gsub(",", "") if entry.company}, #{entry.email.gsub('mailto:', '').gsub(",", "") if entry.email}, #{entry.number.gsub(",", "") if entry.number}, #{entry.url.gsub(",", "") if entry.url}, "
          csv << "#{get_line1(address_array).strip}, #{get_city(address_array).strip}, #{get_state(address_array).strip}, #{get_zip(address_array).strip}"
          csv << "\n"
        end unless entries.blank?
        self.last_scraped_url = url.unshift(root_url).join("/")
        url = paginator.scrape(html)
        url = url.gsub("&amp;", "&").split('/').reject(&:blank?) unless url.blank?
      end
      
      self.csv = csv
      self.save!
    rescue
      self.save
      self.update_attribute("import_errors", $!.message + $!.backtrace.join("\n"))
      raise ScrapeAbortedByErrors
    end
  end
  
  def go!      
    begin
      if self.scrape && (self.csv == nil)
        self.scrape!
      end
      self.update_attribute(:state, "Importing...")
      
      mapper             = Mapper.new(:account_id => self.account.id)
      mapper.mappings    = self.mappings
      
      header_lines_count = self.mappings[:header_lines_count].to_i
      tag_list_field     = self.mappings[:tag_list]
      create_profile     = self.mappings[:create_profile]
      group_name         = self.mappings[:group]
      group              = self.account.groups.find_by_name(group_name)
      self.import_errors, self.imported_lines = [], []
      FasterCSV.parse(self.csv)[header_lines_count + self.imported_rows_count .. -1].in_groups_of(100, false) do |rows|
        Party.transaction do
          rows.each do |row|
            raise "aborting" if row[0] == "c"
            import_row(row, mapper, tag_list_field, create_profile, group)
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
  
  def import_row(row, mapper, tag_list_field, create_profile, group)
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
