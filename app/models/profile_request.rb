#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ProfileRequest < ActiveRecord::Base
  belongs_to :account
  include XlSuite::PicturesHelper
  include XlSuite::Commentable
  include XlSuite::AvailableOnDomain
  
  belongs_to :avatar, :class_name => "Asset", :foreign_key => "avatar_id"
  belongs_to :created_by, :class_name => "Party", :foreign_key => "created_by_id"
  belongs_to :profile
  
  serialize :info, Hash

  has_many :contact_routes, :as => :routable, :order => "position", :dependent => :destroy do
    def addresses(force=false)
      @addresses = nil if force
      @addresses ||= find(:all, :conditions => ["type = ?", AddressContactRoute.name])
    end

    def emails(force=false)
      @emails = nil if force
      @emails ||= find(:all, :conditions => ["type = ?", EmailContactRoute.name])
    end

    def phones(force=false)
      @phones = nil if force
      @phones ||= find(:all, :conditions => ["type = ?", PhoneContactRoute.name])
    end

    def links(force=false)
      @links = nil if force
      @links ||= find(:all, :conditions => ["type = ?", LinkContactRoute.name])
    end
  end
  # Shortcuts for accessing ContactRoute
  has_many :phones, :class_name => "PhoneContactRoute", :as => :routable, :order => "position", :extend => XlSuite::ContactRoutesExtensions, :dependent => :destroy
  has_many :addresses, :class_name => "AddressContactRoute", :as => :routable, :order => "position", :extend => XlSuite::ContactRoutesExtensions, :dependent => :destroy
  has_many :links, :class_name => "LinkContactRoute", :as => :routable, :order => "position", :extend => XlSuite::ContactRoutesExtensions, :dependent => :destroy
  has_many :email_addresses, :class_name => "EmailContactRoute", :as => :routable, :order => "position", :extend => XlSuite::ContactRoutesExtensions, :dependent => :destroy
  
  acts_as_taggable
  acts_as_fulltext %w(first_name middle_name last_name links_as_text phones_as_text addresses_as_text email_addresses_as_text position), :weight => 50 
  
  validates_presence_of :account_id
  
  %w(AddressContactRoute PhoneContactRoute EmailContactRoute LinkContactRoute).each do |class_name|
    singular = class_name.underscore.split("_").first
    plural = class_name.underscore.split("_").first.pluralize
    class_eval <<-EOF
      def any_#{plural}?
        !self.contact_routes.#{plural}.empty?
      end

      def main_#{singular}(force=false)
        if self.contact_routes.#{plural}(force).empty? then
          #{class_name}.new(:routable => self)
        else
          self.contact_routes.#{plural}.first
        end
      end

      # +params+ is either a single level Hash (<code>{:name => "blog", :url => "http://my.blog.com/"}</code>), or
      # a multi-level Hash (<code>{"office" => {"number" => "1-888-123-4321"}}</code>).
      #
      # If +params+ is single level, we update the Main contact route of the correct type, else
      # we update each one in turn.
      def #{singular}=(params)
        if params.values.first.kind_of?(Hash) then
          params.each_pair do |name, attrs|
            # Don't create a contact route if we have nothing to save
            next if attrs.merge(:name => nil).values.join.blank?

            name = name ? name.to_s : "Main"
            model = self.#{plural =~ /email/i ? "email_addresses" : plural}.find_by_name(name)
            if model then
              method = model.new_record? ? :attributes= : :update_attributes
              model.send(method, attrs.merge(:name => name))
            else
              self.#{plural =~ /email/i ? "email_addresses" : plural} << #{class_name}.new(attrs.merge(:routable => self, :name => name, :account => self.account))
            end
          end
        else
          # Turn a single level Hash into a multi-level one, so we don't have
          # to dick around and duplicate code.
          self.#{singular} = {params[:name] => params}
        end
      end
    EOF
  end

  def []( attribute )
    if( attribute == 'full_name' )
      return full_name
    else
      super
    end
  end

  def full_name
    return "#{first_name} #{last_name}"
  end

  def full_name=(name)
    self.name = Name.parse(name)
  end

  def info
    read_attribute(:info) || write_attribute(:info, Hash.new)
  end
  
  def attributes=(new_attributes, guard_protected_attributes = true)
    return if new_attributes.nil?

    attributes = new_attributes.dup
    attributes.stringify_keys!

    multi_parameter_attributes = []
    attributes = remove_attributes_protected_from_mass_assignment(attributes) if guard_protected_attributes

    attributes.each do |k, v|
      if k.include?("(")
        multi_parameter_attributes << [ k, v ]
      else
        send(:"#{k}=", v)
      end
    end

    assign_multiparameter_attributes(multi_parameter_attributes)
  end
  
  protected

  def links_as_text
    self.links.map(&:url)
  end

  def phones_as_text
    self.phones.map do |phone|
      [phone.plain_number, phone.formatted_number]
    end
  end

  def addresses_as_text
    self.addresses.map do |address|
      [address.to_url, address.full_state, address.full_country]
    end
  end

  def email_addresses_as_text
    self.email_addresses.map(&:address)
  end
  
  def method_missing(method, *args, &block)
    method_name = method.to_s.gsub("=", "")
    if self.class.column_names.index(method_name) 
      return super
    end
    writer_method = method.to_s.match(/=$/)
    if writer_method
      self.info.merge!(method_name => args.first)
      return true
    else
      return self.info[method_name.to_s]
    end
  end
  
  def copy_contact_routes_to_party!(party)
    %w(email_addresses links phones addresses).each do |cr_type|
      self.send(cr_type).each do |cr|
        profile_cr = cr.dup
        profile_cr.routable = party
        profile_cr.save!
      end
    end
    true
  end
end
