#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  module DeniableGranteeable
    def self.included(base) #:nodoc:
      base.send :extend, DeniableGranteeable::ClassMethods
      base.send :include, DeniableGranteeable::InstanceMethods

      base.belongs_to :assignee, :polymorphic => true
      base.belongs_to :subject, :polymorphic => true

      base.validates_uniqueness_of :assignee_id, :scope => [:assignee_type, :subject_type, :subject_id]

      base.after_create :update_parties_effective_permissions
      base.after_destroy :update_parties_effective_permissions
    end  

    module ClassMethods
      def destroy_by_assignee_and_subject(assignee, subject)
        object = self.find(:first, :conditions => ["assignee_type=? AND assignee_id=? AND subject_type=? AND subject_id=?", assignee.class.name, assignee.id, subject.class.name, subject.id])
        return false if object.nil?
        object.destroy
      end

      def create_collection_by_assignee_and_subjects(assignee, subjects)
        subjects.each do |subject| 
          unless self.count(:conditions => ["assignee_type=? AND assignee_id=? AND subject_type=? AND subject_id=?", assignee.class.name, assignee.id, subject.class.name, subject.id]) > 0
            self.connection().execute(%Q!
            INSERT INTO #{self.table_name} (`assignee_type`, `assignee_id`, `subject_type`, `subject_id`) VALUES ("#{assignee.class.name}", #{assignee.id}, "#{subject.class.name}", #{subject.id})
            !)
          end
        end
        object = self.find(:first, :conditions => ["assignee_type=? AND assignee_id=? AND subject_type=? AND subject_id=?", assignee.class.name, assignee.id, subjects.last.class.name, subjects.last.id])
        object.send(:update_parties_effective_permissions)
      end

      def destroy_collection_by_assignee_and_subjects(assignee, subjects)
        ids = []
        object = nil
        subjects.each do |subject|
          temp = self.find(:first, :conditions => ["assignee_type=? AND assignee_id=? AND subject_type=? AND subject_id=?", assignee.class.name, assignee.id, subject.class.name, subject.id])
          next unless temp
          object = temp
          ids << temp.id
        end
        return 0 if ids.empty?
        self.delete(ids)
        object.send(:update_parties_effective_permissions)
        ids.size
      end
    end

    module InstanceMethods
      protected
      def update_parties_effective_permissions
        if self.assignee.respond_to?(:update_effective_permissions)
          self.assignee.update_effective_permissions = true
          self.assignee.save!
        else
          parties = []
          parties = self.assignee.groups.inject(parties) {|memo, group| memo << group.total_parties} if self.assignee.respond_to?(:groups)
          parties << self.assignee.total_parties if self.assignee.respond_to?(:total_parties)

          parties.flatten!
          parties.uniq!
          return true if parties.empty?

          MethodCallbackFuture.create!(:models => parties, :method => :generate_effective_permissions, :account => parties.first.account, :priority => 0)
        end
      end
    end
  end
end
