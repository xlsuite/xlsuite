#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Book < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id
  
  #validates_presence_of :name
  #validates_uniqueness_of :name, :scope => :account_id
  
  include XlSuite::AccessRestrictions
  acts_as_taggable

  belongs_to :creator, :class_name => "Party", :foreign_key => :creator_id
  belongs_to :editor, :class_name => "Party", :foreign_key => :editor_id
  belongs_to :product
  
  before_save :update_creator_and_editor
  before_save :calculate_production_cost
  before_save :calculate_cost_per_book
  
  has_many :views, :as => :attachable
  
  has_many :assets, :through => :views, :order => "views.position"
  has_many :pictures, :source => :asset, :through => :views, :order => "views.position", :conditions => 'assets.content_type LIKE "image/%"' 
  alias_method :images, :pictures
  
  has_many :relations, :class_name => "BookRelation"

  DEFINED_COST_FIELDS = %w(indexing proofing typeset text_prep design binding editing misc manuscript printing production)
  
  DEFINED_COST_FIELDS.each do |action|
    acts_as_money "#{action}_cost".to_sym
  end
  
  acts_as_money :cost_per_book
  acts_as_money :manuscript_cost_per_page
  
  DEFINED_RELATIONS = %w(indexers proofers typesetters text_prep_nikuds text_prep_typists
    text_prep_ocrs designers accountants authors binders editors fundraising_managers 
    printers source_locations sponsors translators project_managers manuscript_contacts).freeze
  
  DEFINED_RELATIONS.each do |relation|
    has_many relation.to_sym, :through => :relations, :source => :party, :conditions => "classification = '#{relation.classify}'"

    class_eval <<-EOF
      def #{relation.singularize}_ids
        self.#{relation}.find(:all, :select => "parties.id").map(&:id)
      end
    EOF
  end
  
  def picture_ids
    #AND ((assets.content_type LIKE "image/%"))
    Book.connection.select_values(%Q~SELECT assets.id FROM assets INNER JOIN views ON assets.id = views.asset_id WHERE ((views.attachable_type = 'Book') AND (views.attachable_id = #{self.id})) ORDER BY views.position~)
  end
  alias_method :image_ids, :picture_ids
  
  def attributes_with_field_types
    array = []
    content_columns = self.class.content_columns
    self.attributes.each do |key, value|
      hash = {:field_name => key.to_s, :value => self.send(key).to_s}
      field_type = content_columns.detect{|e| e.name == key.to_s}.type
      field_type = :string if DEFINED_COST_FIELDS.include?(key.gsub("_cost", "")) || key == "cost_per_book"
      hash.merge!(:field_type => field_type.to_s)
      array << hash 
    end
    DEFINED_RELATIONS.each do |relation|
      # First request the ids for the relation and make an array out of it
      ids = Array(self.send("#{relation.singularize}_ids"))
      # Then lookup and collect the corresponding Parties
      parties = ids.collect { |id| Party.find id }
      # Then fashion records in the appropriate format
      records = parties.collect { |party| { :id => party.id, :name => party.name.to_s, :company_name => party.company_name } }

      # { field_type: 'relation', field_name: 'therelations', value: [{id: X, name: 'someone', company_name: 'something}] }
      array << {:field_type => 'relation', :field_name => relation, :value => records}
    end
    array << {:field_type => 'images', :field_name => 'images', :value => self.picture_records}
    
    array
  end
  
  def remove_relation(relation_name, party_ids)
    removed_relation_count = 0
    relations = self.relations.find(:all, :conditions => ["classification = ? AND party_id IN (?)", relation_name, party_ids])
    relations.each do |relation|
      removed_relation_count += 1 if relation.destroy
    end
    removed_relation_count
  end
  
  def duplicate
    new_book = Book.new(self.attributes.reject{|key,value| key=="id"})
    self.relations.each do |relation|
      new_book.relations.build(relation.attributes.reject{|key,value| key=="book_id"})
    end
    new_book
  end
  
  # Returns : [{url: '/somewhere.ext', id: X}]
  def picture_records
    return self.picture_ids.collect do |id|
      asset = Asset.find id
      { #return
        #:url => "#{path_prefix}/#{id}/#{asset.filename}",
        :id => id,
        :filename => asset.filename,
        #:width => asset.width,
        #:height => asset.height,
        :bytes => asset.size,
        :updated_at => asset.updated_at.to_s
      }
    end
  end
  
  protected

  def update_creator_and_editor
    self.creator_name = Party.find(self.creator_id).display_name unless self.creator_id.blank?
    self.editor_name = Party.find(self.editor_id).display_name unless self.editor_id.blank?
  end
  
  def calculate_production_cost
    p_cost = 0

    %w(indexing proofing typeset text_prep design binding editing misc).each do |cost_field|
      if self.send("#{cost_field}_cost") && self.send("#{cost_field}_hours")
        cost = self.send("#{cost_field}_cost").cents
        hours = self.send("#{cost_field}_hours")
        hours = 1 if hours == 0
        p_cost += cost * hours
      end
    end
    
    self.production_cost = Money.new(p_cost.to_i)
  end
  
  def calculate_cost_per_book
    self.amount_printed = 1 if self.amount_printed < 1 || !self.amount_printed
    production_cents = self.production_cost ? self.production_cost.cents : 0
    printing_cents = self.printing_cost ? self.printing_cost.cents : 0
    cpb = ((production_cents + printing_cents) / self.amount_printed).to_i
    self.cost_per_book = Money.new(cpb)
  end    
end
