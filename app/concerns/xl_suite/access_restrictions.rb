#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  module AccessRestrictions
    def self.included(base)
      base.has_many :read_authorizations, :as => :object, :dependent => :destroy
      base.has_many :readers, :through => :read_authorizations, :source => :group

      base.has_many :write_authorizations, :as => :object, :dependent => :destroy
      base.has_many :writers, :through => :write_authorizations, :source => :group

      base.send(:remove_method, :reader_ids=)
      base.send(:remove_method, :writer_ids=)

      base.after_save :update_read_authorizations
      base.after_save :update_write_authorizations
    end

    def public?
      self.readers.empty?
    end

    def private?
      !public?
    end

    def reader_ids
      ids = if self.new_record? then
        @_reader_ids ||= []
      else
        @_reader_ids ||= self.read_authorizations.map(&:group_id)
      end

      ids.dup
    end

    def reader_ids=(group_ids)
      @_reader_ids = clean_group_ids!(group_ids)
    end

    def writer_ids
      ids = if self.new_record? then
        @_writer_ids ||= []
      else
        @_writer_ids ||= self.write_authorizations.map(&:group_id)
      end

      ids.dup
    end

    def writer_ids=(group_ids)
      @_writer_ids = clean_group_ids!(group_ids)
    end

    def readable_by?(party)
      return true if self.new_record?
      return true if self.readers.empty?
      return false unless party
      (self.readers + self.writers).uniq.any? do |group|
        party.member_of?(group)
      end
    end

    def writeable_by?(party)
      return true if self.new_record?
      return false unless party
      return true if self.writers.empty?
      self.writers.any? do |group|
        party.member_of?(group)
      end
    end

    protected
    def clean_group_ids!(group_ids)
      group_ids = group_ids.clone
      group_ids = group_ids.split(",").map(&:strip) if group_ids.kind_of?(String)
      group_ids.reject(&:blank?).map(&:to_i).reject(&:zero?)
    end

    # TODO: Use #replace instead of this code
    def update_read_authorizations
      self.reader_ids
      self.read_authorizations.delete_all unless self.new_record?
      return if @_reader_ids.blank?
      self.account.groups.find(@_reader_ids).each do |group|
        self.read_authorizations.create!(:group => group, :object => self)
      end
    end

    # TODO: Use #replace instead of this code
    def update_write_authorizations
      self.writer_ids
      self.write_authorizations.delete_all unless self.new_record?
      return if @_writer_ids.blank?
      self.account.groups.find(@_writer_ids).each do |group|
        self.write_authorizations.create!(:group => group, :object => self)
      end
    end
  end
end
