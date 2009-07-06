module ActsAsReportable
  def self.included(base)
    base.send :extend, ActsAsReportable::ClassMethods
  end

  class MissingColumn < RuntimeError; end

  module ClassMethods
    def real_columns
      self.report_columns.reject(&:virtual?)
    end

    def virtual_columns
      self.report_columns.select(&:virtual?)
    end

    def report_columns
      return acts_as_reportable_columns unless acts_as_reportable_columns.empty?

      if acts_as_reportable_options[:columns] then
        acts_as_reportable_options[:columns].each do |name|
          column = self.content_columns.detect {|column| column.name == name}
          raise MissingColumn, "Column #{name.inspect} does not exist" unless column
          acts_as_reportable_columns << ReportColumn.new(:human_name => column.human_name, :name => column.name, :model => self.name)
        end
      else
        self.content_columns.each do |column|
          acts_as_reportable_columns << ReportColumn.new(:human_name => column.human_name, :name => column.name, :model => self.name)
        end
      end

      if acts_as_reportable_options[:virtuals] then
        acts_as_reportable_options[:virtuals].each do |name|
          acts_as_reportable_columns << ReportColumn.new(:human_name => name.humanize, :name => name, :model => self.name, :virtual => true)
        end
      else # Add default virtual columns
        # Are we taggable ?
        if self.respond_to?(:find_tagged_with) then
          # Need new columns for tagged_all and tagged_any
          acts_as_reportable_columns << ReportColumn.new(:human_name => "Tagged any", :name => "tagged_any", :model => self.name, :virtual => true)
          acts_as_reportable_columns << ReportColumn.new(:human_name => "Tagged all", :name => "tagged_all", :model => self.name, :virtual => true)
        end
      end

      self.report_relationships.each_pair do |alias_name, relationship|
        klass_name = acts_as_reportable_options[:map][relationship.to_sym] || relationship.singularize
        klass = klass_name.to_s.classify.constantize
        relationship = relationship.singularize
        klass.real_columns.each do |column|
          acts_as_reportable_columns << ReportColumn.new(:human_name => [relationship.humanize, column.human_name].join(" ").downcase.capitalize, :name => [relationship.downcase, column.name].join("_"), :model => klass.name, :relationship => relationship.pluralize, :virtual => true, :table_name => alias_name)
        end
      end

      acts_as_reportable_columns
    end

    # Returns a Hash of +alias_name+ to +relationship_name+.  The relationships are inferred
    # from methods named +join_on_+.  The alias is inferred from +_as_+.  Returns the plural
    # version of the table and alias names.
    #
    # == Examples
    #  class Party
    #    # Relationship from parties to addresses
    #    def join_on_addresses
    #    end
    #
    #    # Relationship from parties to addresses aliased as cr_addresses
    #    def join_on_addresses_as_cr_addresses
    #    end
    #
    #    # Relationship from parties to addresses (which is really contact_routes) aliased as cr_addresses
    #    acts_as_reportable :map => {:addresses => :address_contact_route}
    #    def join_on_addresses_as_cr_addresses
    #    end
    #  end
    def report_relationships
      returning({}) do |relationships|
        ms = self.methods
        ms.delete_if {|name| !name.starts_with?("join_on_")}
        ms.collect! {|name| name.sub("join_on_", "")}
        ms.each do |name|
          relationship_name, alias_name = name.split("_as_", 2)
          alias_name.if_nil { alias_name = relationship_name }
          relationships[alias_name] = relationship_name
        end
      end
    end
    
    # Options is a Hash accepting the following keys:
    # * <tt>:columns</tt>:  The list of physical columns we are allowing
    #                       ourselves to be searched on.  Other columns
    #                       can't be searched (in this model).  By default,
    #                       we add #content_columns.
    # * <tt>:virtuals</tt>: A list of virtual columns that this object knows
    #                       about and can be searched on.  By default, we add
    #                       +tagged_any+ and +tagged_all+ if the object is taggable.
    # * <tt>:map</tt>:      Maps the relationship names to model names (relationship
    #                       must be pluralized, model is the underscored version of
    #                       the class' name).
    def acts_as_reportable(options={})
      options = options.reverse_merge(:map => {})
      write_inheritable_attribute(:acts_as_reportable_options, options)
      write_inheritable_attribute(:acts_as_reportable_columns, [])
      class_inheritable_reader :acts_as_reportable_options, :acts_as_reportable_columns
    end

    def to_count_sql(lines)
      self.flatten_sql_options(self.to_internal_count_sql(lines))
    end

    def to_report_sql(lines)
      self.flatten_sql_options(self.to_internal_report_sql(lines))
    end

    def flatten_sql_options(sql)
      returning(sql) do
        sql[:select] = sql[:select].flatten.map(&:strip).uniq.join(", ") if sql[:select]
        sql[:joins] = sql[:joins].flatten.map(&:strip).uniq.join(" ") if sql[:joins]
        sql[:group] = sql[:group].flatten.map(&:strip).uniq.join(", ") if sql[:group]
        sql[:order] = sql[:order].flatten.map(&:strip).uniq.join(", ") if sql[:order]
        sql[:having] = sql[:having].flatten.map(&:strip).uniq.map {|c| "(#{c})"}.join(" AND ") if sql[:having]

        condition_values = {}
        sql[:conditions][1].each do |e|
          condition_values.merge!(e.symbolize_keys)
        end
        sql[:conditions] = [sql[:conditions][0].flatten.map(&:strip).map {|c| "(#{c})"}.join(" AND "), condition_values] if sql[:conditions]
        #sql[:conditions] = [sql[:conditions][0].flatten.map(&:strip).map {|c| "(#{c})"}.join(" AND "), *sql[:conditions][1]] if sql[:conditions]

        sql.delete(:joins) if sql[:joins].blank?
        sql.delete(:order) if sql[:order].blank?
        sql.delete(:conditions) if sql[:conditions][0].blank?
        sql.delete(:group) if sql[:group].blank?
        sql.delete(:having) if sql[:having].blank?
      end
    end

    def to_internal_count_sql(lines)
      returning(self.to_internal_report_sql(lines)) do |options|
        options[:select] = options[:select].select {|e| e =~ /count\(/i}
        options[:select].unshift "COUNT(*) count_all"
        options.delete(:order)
      end
    end

    def to_internal_report_sql(lines)
      returning(:select => ["#{self.table_name}.*"], :joins => [], :order => [], :conditions => [[], []], :group => [], :having => []) do |sql|
        lines.reject {|l| l.field.blank?}.each do |line|
          self.send("#{line.field}_to_report_sql", line, sql)
        end
      end
    end

    def account
      Thread.current[:account]
    end

    def account=(value)
      Thread.current[:account] = value
    end

    def run_report(account, lines, options={})
      self.account = account
      with_scope(:find => options) do
        account.send(self.name.tableize).find(:all, self.to_report_sql(lines))
      end
    end

    def count_report(account, lines, options={})
      self.account = account
      with_scope(:find => options) do
        account.send(self.name.pluralize.downcase).find(:all, self.to_count_sql(lines)).first.count_all.to_i
      end
    end

    def tagged_all_to_report_sql(line, sql)
      ids = tagged_with_ids(:all, line)
      operator = line.excluded? ? "NOT IN" : "IN"
      sql[:conditions][0] << "#{self.table_name}.#{self.primary_key} #{operator} (:tag_object_ids)"
      sql[:conditions][1] << {:tag_object_ids => (ids.empty? ? [0] : ids)}
    end

    def tagged_any_to_report_sql(line, sql)
      ids = tagged_with_ids(:any, line)
      operator = line.excluded? ? "NOT IN" : "IN"
      sql[:conditions][0] << "#{self.table_name}.#{self.primary_key} #{operator} (:tag_object_ids)"
      sql[:conditions][1] << {:tag_object_ids => (ids.empty? ? [0] : ids)}
    end
 
    def tagged_with_ids(type, line)
      self.account.send(self.name.pluralize.downcase).find_tagged_with(type => line.value, :select => "#{self.table_name}.#{self.primary_key}").map(&:id)
    end

    def method_missing(symbol, *args)
      return super unless symbol.to_s =~ /_to_report_sql$/
      line, sql = args
      attr_name = symbol.to_s.sub("_to_report_sql", "")
      self.report_columns.detect {|col| col.name == attr_name}.if_not_nil {|col| col.to_report_sql(line, sql, self)}
    end
  end
end
