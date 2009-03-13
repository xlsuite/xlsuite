#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  module Permissionable
    def permissions=(*args)
      PermissionGrant.delete_all("assignee_id = #{self.id} AND assignee_type = '#{self.class.name}'")
      args.flatten.map do |p|
        case p
        when String, Symbol
          Permission.find_or_create_by_name(p.to_s)
        when Permission
          p
        else
          raise ArgumentError, "Expected to find a Permission, String or Symbol, got a #{p.class.name}"
        end
      end.each do |permission|
        if self.respond_to?(:update_effective_permissions)
          ActiveRecord::Base.connection().execute(%Q~
            INSERT INTO permission_grants (`assignee_id`, `assignee_type`, `subject_type`, `subject_id`) VALUES(#{self.id}, '#{self.class.name}', 'Permission', #{permission.id})
          ~)
        else
          self.permission_grants.create!(:subject => permission, :assignee => self)
        end
      end

      if self.respond_to?(:update_effective_permissions)
        self.update_effective_permissions = true
        self.save!
      end      
    end

    def permission_ids=(*args)
      PermissionGrant.delete_all("assignee_id = #{self.id} AND assignee_type = '#{self.class.name}'")
      self.permissions = Permission.find(args.flatten)

      if self.respond_to?(:update_effective_permissions)
        self.update_effective_permissions = true
        self.save!
      end
      
      self.permissions
    end

    def append_permissions(*args)
      my_permissions = self.permissions(true)

      PermissionGrant.delete_all("assignee_id = #{self.id} AND assignee_type = '#{self.class.name}'")
      #self.permission_grants.delete_all #<= for some reason, this doesn't work
      my_permissions += args.flatten.map do |perm|
        Permission.find_or_create_by_name(perm.to_s)
      end

      my_permissions.uniq.each do |perm|
        self.permission_grants.create!(:subject => perm, :assignee => self)
      end
      
      if self.respond_to?(:update_effective_permissions)
        self.update_effective_permissions = true
        self.save!
      end
      
      self.permissions(true)
    end

    def remove_permissions(*args)
      args.collect!{|a| a.to_s.underscore}
      self.permissions = self.permissions.reject {|p| args.include?(p.name)}

      if self.respond_to?(:update_effective_permissions)
        self.update_effective_permissions = true
        self.save!
      end
      
      self.permissions
    end

=begin
    def effective_permissions
      perms = self.permissions(true)
      perms += (self.groups - [self]).map(&:effective_permissions)
      perms = perms.flatten.uniq
      perms -= self.denied_permissions if self.respond_to?(:denied_permissions)
      perms.sort_by(&:name)
    end
=end

    def effective_permissions
      (self.total_granted_permissions - self.total_denied_permissions).sort_by(&:name)
    end

    def total_granted_permissions
      perms = self.permissions
      perms += self.children.map(&:total_granted_permissions)
      perms.flatten!
      perms.uniq!
      perms
    end
    
    def total_denied_permissions
      denied_perms = self.denied_permissions
      denied_perms += self.children.map(&:total_denied_permissions)
      denied_perms.flatten!
      denied_perms.uniq!
      denied_perms
    end        
  end
end
