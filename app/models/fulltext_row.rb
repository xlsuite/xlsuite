#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

# Represents one model (named +subject+), indexable by MySQL.
class FulltextRow < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id, :if => :account_id_required?

  belongs_to :subject, :polymorphic => true

  MINIMUM_QUERY_LENGTH = 4

  class << self
    # Searches for model instances and returns FulltextRow instances.  Use
    # #label to quickly display a search result listing, instead of
    # instantiating the #subject immediately.
    def search(query, options={})
      return [] if query.length < MINIMUM_QUERY_LENGTH

      select_clause = [options.delete(:select) || "*"]
      select_clause << "#{fulltext(query)} score"
      with_scope(:find => {:select => select_clause.join(", "), :conditions => fulltext(query)}) do
        self.find(:all, options)
      end
    end
    
    def count_results(query, options={})
      return 0 if query.length < MINIMUM_QUERY_LENGTH
      with_scope(:find => {:conditions => fulltext(query)}) do
        self.count(:all, :conditions => options.delete(:conditions))
      end
    end

    # Searches for instances of the specified class.  Returns instances of
    # the class rather than FulltextRow instances.
    def search_by_class(klass, query, options={})
      options = options.clone
      if query.blank?
        klass.find(:all, options)
      else
        rows = with_scope(:find => {:conditions => {:subject_type => klass.name},
            :joins => "INNER JOIN #{klass.table_name} ON #{klass.table_name}.id = #{self.table_name}.subject_id"}) do
          klass_scope = klass.scoped_methods.last
          if klass_scope && klass_scope[:find] then
            select_clause = [klass_scope[:find][:select], "#{klass.table_name}.*"].compact.join(", ")
            with_scope(:find => {:conditions => klass_scope[:find][:conditions], :order => klass_scope[:find][:order]}) do
              search(query, options.merge(:select => select_clause))
            end
          else
            search(query, options)
          end
        end

        rows.map do |row|
          klass.send(:instantiate, row.attributes)
        end
      end
    end

    def count_by_class(klass, query, options={})
      options = options.clone
      if query.blank?
        klass.count(options)
      else
        with_conditions = !options[:conditions].blank?
        klass_scope = klass.scoped_methods.last
        rows_with_scope_find_option = {:conditions => {:subject_type => klass.name}}
        rows_with_scope_find_option.merge!(:joins => "INNER JOIN #{klass.table_name} ON #{klass.table_name}.id = #{self.table_name}.subject_id") if with_conditions
        rows = with_scope(:find => rows_with_scope_find_option) do
          if klass_scope && klass_scope[:find] && klass_scope[:find][:conditions]
            find_conditions_scope = klass_scope[:find][:conditions]
            find_conditions_scope = find_conditions_scope.gsub(/\A([^\.]+)\./, "") unless with_conditions
            with_scope(:find => {:conditions => find_conditions_scope}) do       
              count_results(query, options)
            end
          else
            count_results(query, options)
          end
        end  
      end
    end

    def fulltext(query) #:nodoc:
      "MATCH(#{self.table_name}.label, #{self.table_name}.body) AGAINST (#{quote_value(query)} IN BOOLEAN MODE)"
    end
  end
  
  protected
  def account_id_required?
    (["Account", "Configuration"].detect {|c| c == self.subject_type}).blank?
  end
end
