#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Configuration < ActiveRecord::Base
  include DomainPatternsSplitter

  acts_as_fulltext %w(name), %w(group_name value_as_text domain_patterns description)

  belongs_to :account

  attr_accessible :name, :group_name, :description, :account_id, :account, :domain_patterns

  before_validation :set_default_domain_patterns

  validates_presence_of :name
  validate :account_name_cannot_be_same_as_system_config

  before_destroy :find_other_configurations_with_same_name
  after_destroy :set_only_config_domain_patterns_to_default
  
  before_create :generate_random_uuid

  def name=(value)
    write_attribute(:name, self.class.normalize(value))
  end

  def set_value!(val)
    self.set_value(val)
    self.save!
  end

  class << self
    def find_or_initialize_by_name_and_account_id(name, account_id)
      super(normalize(name), account_id)
    end

    def get(name, account_or_domain=nil)
      x = retrieve(name, account_or_domain)
      if x then x.value else nil end
    end

    def set_full(name, value, group_name, description, account)
      logger.info "Setting config values for #{name} to #{value}"
      Configuration.set(name, value, account)
      attrs = {:group_name => group_name, :description => description}
      Configuration.retrieve(name, account).update_attributes(attrs)
    end

    def set_default(name, value)
      conf_class = class_from_value(value)
      conf = conf_class.find_or_initialize_by_name_and_account_id(name, nil)
      conf.set_value!(value)
      nil
    end

    def set(name, value, account)
      raise ArgumentError, "Must provide account on which we set the value" if account.blank?

      conf_class = class_from_value(value)
      conf = conf_class.find_or_initialize_by_name_and_account_id(name, account.id)
      conf.set_value!(value)
      nil
    end

    def retrieve(name, account_or_domain=nil)
      name = normalize(name)

      case account_or_domain
      when Account
        account = account_or_domain
        if account && account.id
          conf = find_by_name_and_account_id(name, account.id)
          return conf if conf
        end
        
        # Try to move up an account (parent account)
        parent_account = account.parent
        if parent_account
          conf = retrieve(name, parent_account)
          return conf if conf
        end

        # Try to find the default value
        conf = find(:first, :conditions => ["account_id IS NULL AND domain_patterns = ? AND name = ?", "**", name])
        conf = find_by_name_and_account_id(name, nil) unless conf
        return conf if conf
      when Domain
        domain = account_or_domain
        configs = Configuration.find_all_by_name_and_account_id(name, domain.account_id)
        unless configs.empty?
          conf = configs.best_match_for_domain(domain)
          return conf if conf
        end
        
        # Try to find the default value
        conf = find(:first, :conditions => ["account_id IS NULL AND domain_patterns = ? AND name = ?", "**", name])
        conf = find_by_name_and_account_id(name, nil) unless conf
        return conf if conf
      when NilClass
        conf = find(:first, :conditions => ["account_id IS NULL AND domain_patterns = ? AND name = ?", "**", name])
        conf = find_by_name_and_account_id(name, nil) unless conf
        return conf if conf
      end

      raise ConfigurationNotFoundException, name
    end

    def normalize(name)
      raise "Cannot read or change configuration if no name provided" if name.blank?
      name.to_s.downcase
    end

    protected
    def class_from_value(value)
      if value.class == Product
        ProductConfiguration
      elsif value.class == ProductCategory
        ProductCategoryConfiguration
      elsif value.class == Party
        PartyConfiguration
      elsif value.respond_to?(:to_str)
        StringConfiguration
      elsif value.class == TrueClass or value.class == FalseClass
        BooleanConfiguration
      elsif value.respond_to?(:integer?) and value.integer?
        IntegerConfiguration
      else
        FloatConfiguration
      end
    end
  end

  def attributes_for_copy_to(account)
    self.attributes.dup.merge(:account_id => account.id, :party_id => nil, :domain_patterns => "**")
  end

  protected

  def find_other_configurations_with_same_name
    return true unless self.account
    return false unless self.account.configurations.count(:conditions => ["name = ?", self.name]) > 1
    true
  end

  def set_default_domain_patterns
    self.domain_patterns = "**" if self.domain_patterns.blank?
  end

  def set_only_config_domain_patterns_to_default
    return true unless self.account
    configs = self.account.configurations.find_all_by_name(self.name)
    if configs.size == 1
      configs.first.update_attribute(:domain_patterns, "**")
    end
  end

  def account_name_cannot_be_same_as_system_config
    return true if !self.account_wide
    return true if !self.account_id
    if Configuration.find_by_name_and_account_id_and_account_wide(self.name, nil, 0)
      self.errors.add(:name, "Configuration name cannot be the same as a system-wide configuration")
      return false
    end
  end

  def value_as_text
    self.value.to_s
  end
end
