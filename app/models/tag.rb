#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Tag < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id

  has_many :taggings

  validates_presence_of :name
  validates_length_of :name, :within => 1..240
  validates_format_of :name, :with => /\A[A-Za-z0-9][-\w\/:.]*\Z/

  auto_scope \
      :system => {
          :find => {:conditions => {:system => true}},
          :create => {:system => true}},
      :regular => {
          :find => {:conditions => {:system => false}},
          :create => {:system => false}}

  def to_liquid
    TagDrop.new(self)
  end

  def products
    Product.find_tagged_with(:all => self.name, :conditions => {:account_id => self.account_id})
  end
  
  def self.parse(list)
    return Array.new if list.blank?
    tag_list = Array.new

    case list
    when Array
      tag_list = list
    else
      # first, pull out the quoted tags
      list.gsub!(/(['"])(.*?)\1/ ) { tag_list << $2; "" }

      # then, replace all commas with a space
      list.gsub!(/,/, " ")

      # then, get whatever's left and normalize the whitespace
      tag_list.concat list.split(/\s+/)
    end

    tag_list.reject(&:empty?).uniq
  end

  def self.within(account)
    Tag.with_scope(:find => {:conditions => {:account_id => account.id}}, :create => {:account => account}) do
      yield
    end
  end

  # This is pretty inefficient, would be nice if the taggings.taggable polymorphic
  # association had a way to directly pull out and instantiate the associations
  def tagged
    @tagged ||= taggings.collect { |tagging| tagging.taggable }
  end

  def on(taggable)
    return unless self.valid?
    count = self.taggings.count(:all, :conditions => ['taggable_id = ? AND taggable_type = ?', taggable.id, taggable.class.name])
    self.taggings.create(:taggable => taggable) if count.zero?
  end

  def ==(comparison_object)
    super || name == comparison_object.to_s
  end

  def to_s
    name
  end

  def count
    read_attribute('count').to_i
  end

  def human_name
    self.name.split('-')[0 .. -2].join(' ').titleize
  end

  def to_param
    self.name.split('-')[0 .. -2].join('-')
  end

  def main_identifier
    self.to_s
  end

  class << self
    def with_prefix(*args)
      raise ArgumentError, "No block given" unless block_given?
      options = args.last.is_a?(Hash) ? args.pop : {}
      with_prefix_name_scope(*args) do
        yield
      end
    end

    def with_suffix(*args)
      raise ArgumentError, "No block given" unless block_given?
      options = args.last.is_a?(Hash) ? args.pop : {}
      with_suffix_name_scope(*args) do
        yield
      end
    end
  end

  protected
  class << self
    def with_suffix_name_scope(*args)
      conditions = Array.new
      values = Array.new

      args.each do |suffix|
        conditions << 'name LIKE ?'
        values << "%#{suffix}"
      end

      with_scope(:find => {:conditions => [conditions.join(' OR '), values]}) do
        yield
      end
    end

    def with_prefix_name_scope(*args)
      conditions = Array.new
      values = Array.new

      args.each do |prefix|
        conditions << 'name LIKE ?'
        values << "#{prefix}%"
      end

      with_scope(:find => {:conditions => [conditions.join(' OR '), values]}) do
        yield
      end
    end
  end
end
