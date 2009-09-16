#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Mapper < ActiveRecord::Base
  belongs_to :account
  serialize :mappings
  attr_protected :mappings

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :account_id

  # Returns a Party object from an Array of strings, using the
  # +mappings+ to determine which column goes in which property.
  def to_object(row)
    returning(Party.create!(:account_id => self.account_id)) do |root|
      self.mappings[:map].each_with_index do |mapping, column|
        next if mapping.nil? || row[column].blank? || !mapping.has_key?(:field) || mapping[:field].blank?
        tr_row_column = row[column].to_s
        
        next if(mapping[:model] == "LinkContactRoute" && mapping[:field] == "url" && !self.mappings[:ignore_websites_regex].blank? && tr_row_column =~ Regexp.new(self.mappings[:ignore_websites_regex]))
        
        obj = mapping_to_object(mapping, root)
        
        case mapping[:tr]
        when /titleize/i
          tr_row_column = tr_row_column.titleize
        when /lowercase/i
          tr_row_column = tr_row_column.downcase
        when /uppercase/i
          tr_row_column = tr_row_column.upcase
        when /stripped/i
          tr_row_column = tr_row_column.gsub(/\W/i,"")
        else 
          # do nothing As-is transformation
        end
        if mapping[:field] =~ /tag_list/i
          obj.tag_list = obj.tag_list << " #{tr_row_column.gsub(';', ',')}"
        elsif mapping[:field] =~ /company_name/i
          obj.send("#{mapping[:field]}=", tr_row_column[0..59])
        elsif mapping[:field] =~ /email_address/i
          obj.send("#{mapping[:field]}=", extract_email(tr_row_column))
        elsif mapping[:field] =~ /avatar/i
          tr_row_column = tr_row_column.strip if tr_row_column
          if tr_row_column =~ /\A(?:ftp|https?):\/\/.*\Z/i
            # external url
            asset = self.account.assets.create!(:external_url => tr_row_column)
            obj.avatar = asset if asset
          else
            # find file in database
            path = tr_row_column.split(/\//).reject(&:blank?)
            unless path.blank?
              filename = path.pop
              path.shift
              asset = self.account.assets.find_by_path_and_filename(path.join('/'), filename)
              obj.avatar = asset if asset
            end
          end
        elsif mapping[:field] =~ /notes/i
          obj.notes.build(:name => "Import", :body => tr_row_column, :account => obj.account)
        else
          obj.send("#{mapping[:field]}=", tr_row_column)
        end
      end
    end
  end

  def extract_email(string)
    string.split.each do |s|
      return s if s =~ EmailContactRoute::ValidAddressRegexp
    end
    return ""
  end

  # Returns an Array of strings that respects the mapping.
  def from_object(object)
    returning(Array.new(self.mappings.size)) do |row|
      self.mappings.each_with_index do |mapping, column|
        obj = mapping_to_object(mapping, root)
        row[column] = obj.send("#{mapping[:field]}").to_s
      end
    end
  end

  def self.decode_mappings(mappings)
    return {} if mappings.nil?
    mappings = mappings.clone || {}
    hash = {:header_lines_count => mappings[:header_lines_count].to_i, :tag_list => mappings[:tag_list], 
            :create_profile => mappings[:create_profile], :group => mappings[:group], 
            :exclude_no_email => mappings[:exclude_no_email], :domain_id => mappings[:domain_id],
            :action_handler_id => mappings[:action_handler_id], :ignore_websites_regex => mappings[:ignore_websites_regex]}
    map_array = []
    map = mappings[:map]
    map = map.to_a
    map = map.sort_by {|e| e[0].to_i}
    for mapping in map.map {|e| e[1]}
      if mapping[:model].blank? || mapping[:field].blank?
        map_array << nil
      else
        map_array << mapping
      end
    end
    hash.merge!({:map => map_array})
    return hash
  end
  
  def self.default_mappings
    [{:map=>[{:name=>"", :field=>"first_name", :tr=>"As-is", :model=>"Party"}, 
             {:name=>"", :field=>"last_name", :tr=>"As-is", :model=>"Party"}, 
             {:name=>"", :field=>"position", :tr=>"As-is", :model=>"Party"}, 
             {:name=>"", :field=>"company_name", :tr=>"As-is", :model=>"Party"}, 
             {:name=>"Main", :field=>"line1", :tr=>"As-is", :model=>"AddressContactRoute"}, 
             {:name=>"Main", :field=>"city", :tr=>"As-is", :model=>"AddressContactRoute"}, 
             {:name=>"Main", :field=>"state", :tr=>"As-is", :model=>"AddressContactRoute"}, 
             {:name=>"Main", :field=>"zip", :tr=>"As-is", :model=>"AddressContactRoute"}, 
             {:name=>"Office", :field=>"number", :tr=>"As-is", :model=>"PhoneContactRoute"}, 
             {:name=>"Cell", :field=>"number", :tr=>"As-is", :model=>"PhoneContactRoute"}, 
             {:name=>"Fax", :field=>"number", :tr=>"As-is", :model=>"PhoneContactRoute"}, 
             {:name=>"Main", :field=>"email_address", :tr=>"As-is", :model=>"EmailContactRoute"}, 
             {:name=>"Company", :field=>"url", :tr=>"As-is", :model=>"LinkContactRoute"}, 
             {:name=>"", :field=>"avatar", :tr=>"As-is", :model=>"Party"}]},
     {:map=>[{:name=>"", :field=>"company_name", :tr=>"As-is", :model=>"Party"}, 
             {:name=>"Main", :field=>"email_address", :tr=>"As-is", :model=>"EmailContactRoute"},
             {:name=>"Main", :field=>"number", :tr=>"As-is", :model=>"PhoneContactRoute"}, 
             {:name=>"Company", :field=>"url", :tr=>"As-is", :model=>"LinkContactRoute"}, 
             {:name=>"Main", :field=>"line1", :tr=>"As-is", :model=>"AddressContactRoute"},
             {:name=>"Main", :field=>"city", :tr=>"As-is", :model=>"AddressContactRoute"}, 
             {:name=>"Main", :field=>"state", :tr=>"As-is", :model=>"AddressContactRoute"}, 
             {:name=>"Main", :field=>"zip", :tr=>"As-is", :model=>"AddressContactRoute"},
             {:name=>"", :field=>"avatar", :tr=>"As-is", :model=>"Party"}]}
    ]
  end
  
  protected
  def mapping_to_object(mapping, root)
    case mapping[:model]
    when "Party"
      root
    when "EmailContactRoute"
      root.email_addresses.detect {|e| e.name.downcase == mapping[:name].downcase} || root.email_addresses.build(:name => mapping[:name].capitalize, :account_id => self.account_id)
    when "PhoneContactRoute"
      root.phones.detect {|e| e.name.downcase == mapping[:name].downcase} || root.phones.build(:name => mapping[:name].capitalize, :account_id => self.account_id)
    when "AddressContactRoute"
      root.addresses.detect {|e| e.name.downcase == mapping[:name].downcase} || root.addresses.build(:name => mapping[:name].capitalize, :account_id => self.account_id)
    when "LinkContactRoute"
      root.links.detect {|e| e.name.downcase == mapping[:name].downcase} || root.links.build(:name => mapping[:name].capitalize, :account_id => self.account_id)
    end
  end
end
