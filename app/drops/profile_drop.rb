#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ProfileDrop < Liquid::Drop
  attr_reader :profile
  delegate :id, :party, :honorific, :first_name, :last_name, :middle_name, :full_name, :display_name, :company_name, :position,
    :avatar, :alias, :quick_description, :gmap_query, :info, :tags, :tag_list, :approved_comments_count, :unapproved_comments_count,
    :addresses, :email_addresses, :links, :phones, :main_address, :main_email, :main_link, :main_phone, :has_alias?, 
    :created_at, :updated_at, :custom_url, :claimed?, :twitter_username, :blog_post_comment_notification, 
    :listing_comment_notification, :product_comment_notification, :profile_comment_notification, :to => :profile

  def initialize(profile)
    @profile = profile
  end

  alias_method :forum_alias, :alias
  
  def available_on_domains
    self.profile.party.available_on_domains.map(&:to_liquid)
  end
  
  def available_on_domain_names
    self.profile.party.available_on_domains.map(&:name).join(",")
  end
  
  def owned_profiles
    self.profile.party.owned_profiles
  end
  
  def product_category
    self.profile.party.product_category
  end
  
  def avatar_url
    self.profile.avatar ? self.profile.avatar.src : "/images/Mr-Smith.jpg"
  end
  
  Asset::THUMBNAIL_SIZES.merge(:full => "").keys.each do |name|
    self.class_eval <<-EOF
      def #{name}_avatar_url
        if self.profile.avatar
          thumb = self.profile.avatar.thumbnails.find_by_thumbnail('#{name}')
          thumb ? thumb.src : "public/images/thumbisbeinggen.gif"
        else
          "/images/Mr-Smith.jpg"
        end
      end
    EOF
  end

  def name
    self.profile.name ? self.profile.name.to_liquid : ""
  end

  def info_array
    titles = []
    self.profile.info[:title].each_pair {|key, value| titles << [value, self.profile.info[:body][key].to_s]} if !self.profile.info.blank? && self.profile.info[:title]
    titles
  end
  
  def info_pair
    self.profile.info.to_a
  end

  def need_password
    self.profile.party.password_hash.blank?
  end

  def ==(other)
    self.profile.party.id == other.profile.party.id
  end

  %w(listings recent_posts feeds product_categories products).each do |relation_name|
    self.class_eval <<-EOF
      def #{relation_name}
        self.profile.party.#{relation_name}.map(&:to_liquid)
      end
    EOF
  end

  %w(pictures flash_files shockwave_files multimedia audio_files other_files).each do |method_name|
    self.class_eval <<-EOF
      def #{method_name}
        self.profile.party.#{method_name}.collect {|e| AssetDrop.new(e)}
      end
    EOF
  end

  %w(phones links addresses email_addresses).each do |model|
    %w(main home office fax cell mobile).each do |name|
      class_eval <<-EOF
        def #{name}_#{model}
          self.profile.#{model}.#{name.pluralize}
        end
      EOF
    end
  end

  def before_method(method)
    return self.profile.send(method) unless self.class.instance_methods.include?(method.to_s)  
    nil
  end

  def approved_comments
    self.profile.approved_comments unless self.profile.hide_comments
  end

  def comments_hidden?
    self.profile.hide_comments
  end
  
  def average_rating
    (self.profile.average_comments_rating * 10).round.to_f / 10
  end

  def comments_always_approved
    self.profile.comment_approval_method =~ /always approved/i ? true : false
  end

  def comments_moderated
    self.profile.comment_approval_method =~ /^moderated$/i ? true : false
  end
  
  def comments_off
    self.profile.comment_approval_method =~ /no comments/i ? true : false
  end
  
  def has_blog
    self.profile.party.blogs.count > 0
  end
  
  def blogs
    self.profile.party.blogs.map(&:to_liquid)
  end
  
  def blog_posts
    self.profile.party.blog_posts.published.by_publication_date.map(&:to_liquid)
  end
  
  def created_listings
    self.profile.party.created_listings.map(&:to_liquid)
  end
  
  def created_groups
    self.profile.party.created_groups.map(&:to_liquid)
  end
  
  def public_groups
    self.profile.party.created_groups.public.map(&:to_liquid)
  end
  
  def private_groups
    self.profile.party.created_groups.private.map(&:to_liquid)
  end
  
  def joined_groups
    self.profile.party.groups.map(&:to_liquid)
  end
  
  def joined_public_groups
    self.profile.party.groups.public.map(&:to_liquid)
  end
  
  def joined_private_groups
    self.profile.party.groups.private.map(&:to_liquid)
  end
  
  def company_name_or_full_name
    return self.profile.company_name unless self.profile.company_name.blank?
    return self.profile.full_name
  end
  
  def editable_by_user
    return false unless self.context && self.context["user"] && self.context["user"].party
    return self.profile.writeable_by?(self.context["user"].party)
  end
  alias_method :writeable_by?, :editable_by_user
  
  def confirmed
    return self.profile.party.confirmed?
  end
  
  def point
    self.profile.read_attribute(:point) || self.profile.read_attribute(:own_point)
  end
  
  def create_first_blog
    self.profile.create_first_blog(self.context["domain"].domain)
  end
end
