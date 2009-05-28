# Makes a model searchable using MySQL's fulltext index.
#
# = Usage
#  class MyModel < ActiveRecord::Base
#    acts_as_fulltext %w(), %w(), {}
#  end
#
# The first parameter to #acts_as_fulltext is what will appear as the label
# of search results. The second parameter identifies additional fields that
# should be indexed.  These won't show up in the search results.  The third
# parameter is a Hash of options.
#
# The values returned from the fields will be flattened (if Arrays), and
# normalized to date/time strings if Date, Time or DateTime instances.
module ActsAsFulltext
  def self.included(base)
    base.send :include, ActsAsFulltext::InstanceMethods
    base.send :extend, ActsAsFulltext::ClassMethods
  end

  module ClassMethods
    # Declares this model to be fulltext searchable.
    def acts_as_fulltext(*args)
      options = args.last.kind_of?(Hash) ? args.pop : {}
      options.reverse_merge(:weight => 100)

      case args.size
      when 1
        options[:labels] = [args[0].shift].flatten
        options[:fields] = [args[0]].flatten
      when 2
        options[:labels] = [args.shift].flatten
        options[:fields] = [args.shift].flatten
      else
        raise ArgumentError, "Expected 1 or 2 args describing the fields to index, found #{args.size} (plus options)" 
      end

      write_inheritable_hash :fulltext_options, options
      logger.debug {"#{self.name} fulltext options: #{options.inspect}"}
      has_one :fulltext_row, :as => :subject#, :dependent => :delete
      after_destroy :create_fulltext_row_update_deletion
      after_save :create_fulltext_row_update
      #after_save :update_fulltext_index
    end

    # Rebuilds the fulltext index of this class from scratch.
    def rebuild_index
      returning(nil) do
        puts "#{Time.now.utc}: Removing existing fulltext rows from database"
        FulltextRow.delete_all(["subject_type = ?", self.name])
        ids = self.connection.select_values("SELECT id FROM #{table_name}")
        total_ids = ids.length
        puts "#{Time.now.utc}: Rebuilding #{self.name} index on #{total_ids} objects"
        print "#{Time.now.utc}: "
        number_rebuilt, step, group_size = 0.0, 1000, 100
        next_target = step
        ids.in_groups_of(group_size, false) do |group|
          self.find(:all, :conditions => ["id IN (?)", group]).each(&:update_fulltext_index)
          print "."; $stdout.flush
          number_rebuilt += group.length
          if number_rebuilt >= next_target then
            printf " %.2f%% done\n%s: ", (number_rebuilt / total_ids * 100), Time.now.utc
            next_target += step
          end
        end
        puts "#{Time.now.utc}: #{name} index rebuilt"
      end
    end

    # Searches for instances of this class using a natural language query.
    # Returns instances of this model, ordered by relevancy.  +options+
    # are regular ActiveRecord #find options (:limit, :offset, :conditions, etc).
    def search(query, options={})
      FulltextRow.search_by_class(self, query, options)
    end
    
    def count_results(query, options={})
      FulltextRow.count_by_class(self, query, options)
    end
  end

  module InstanceMethods
    def fulltext_options #:nodoc:
      self.class.read_inheritable_attribute(:fulltext_options)
    end
    
    # after save to queue FulltextRow update or create
    def create_fulltext_row_update
      t_attributes = {:subject_type => self.class.name, :subject_id => self.id, :deletion => false}
      t_attributes.merge!(:account_id => self.account_id) if self.respond_to?(:account_id)
      FulltextRowUpdate.create(t_attributes)
      true
    end
    
    # after destroy callback to queue FulltextRow deletion
    def create_fulltext_row_update_deletion
      f = FulltextRowUpdate.find(:first, :conditions => {:subject_type => self.class.name, :subject_id => self.id})
      if f
        f.deletion = true
        f.save
      else
        t_attributes = {:subject_type => self.class.name, :subject_id => self.id, :deletion => true}
        t_attributes.merge!(:account_id => self.account_id) if self.respond_to?(:account_id)
        FulltextRowUpdate.create(t_attributes)
      end
      true
    end

    # after save callback that updates the fulltext row associated with this model.
    def update_fulltext_index
      options = self.fulltext_options
      subject_type = self.class.name
      subject_type = "Configuration" if self.kind_of?(Configuration)
      row = FulltextRow.find(:first, :conditions => ["subject_type=? AND subject_id=?", subject_type, self.id])
      row = row || self.build_fulltext_row
      
      row.subject_type = subject_type
      row.account_id = self.account_id if self.respond_to?(:account_id)
      row.label, row.body = self.fulltext_values
      row.subject_updated_at = self.respond_to?(:updated_at) ? self.updated_at : nil
      row.weight = options[:weight]
      row.save
    end

    def fulltext_values
      options = self.fulltext_options
      label_fields, other_fields = options[:labels], options[:fields]
      [fulltext_field_values(label_fields), fulltext_field_values(other_fields)]
    end

    def fulltext_field_values(field_names) #:nodoc:
      fulltext_normalize(field_names.map {|field| send(field)})
    end

    def fulltext_normalize(value) #:nodoc:
      case value
      when String # String is Enumerable, so... we must take care of it before Array, Enumerable below
        value
      when Date, Time, DateTime
        [value.to_s(:iso), value.to_s(:long), value.to_s(:short), value.to_s].join(" ")        
      when Array, Enumerable
        value.flatten.reject(&:blank?).map {|v| fulltext_normalize(v)}.join(" ")
      when Hash
        [value.keys, value.values].flatten.reject(&:blank?).map {|v| fulltext_normalize(v)}.join(" ")
      else
        value.to_s
      end
    end
  end
end
