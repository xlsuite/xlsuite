#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PartyDrop < Liquid::Drop
  attr_reader :party
  delegate :id, :email, :honorific, :first_name, :last_name, :middle_name, :full_name, :biography, :avatar, :groups,
    :company_name, :position, :info, :forum_alias, :display_name, :quick_description, :gmap_query, :blogs,
    :posts, :created_listings, :created_groups, :profile, :purchased_products, :last_logged_in_at, 
    :granted_products, :granted_blogs, :granted_assets, :granted_groups, :uuid, :confirmed_at, 
    :affiliate_id, :affiliate_username, :affiliate_account_uuid, :has_affiliate_account?, :twitter_username, :to => :party

  def initialize(party)
    @party = party
  end
  
  def blog_post_count
    self.party.account.blog_posts.find_all_by_author_id(self.party.id).size
  end
  
  def profile?
    self.party.profile ? true : false
  end
  
  def create_profile
    if self.party.profile
      return self.party.profile
    else
      profile = self.party.account.profiles.create
      profile.tag_list = party.tag_list
      profile.save
      self.party.profile = profile
      self.party.save!
      return profile.reload
    end
  end

  def need_password
    party.password_hash.blank?
  end
  
  def listings
    party.listings.map(&:to_liquid)
  end

  def avatar_url
    party.avatar ? "/admin/assets/#{party.avatar_id}/download?size=mini" : "/images/Mr-Smith.jpg"
  end

  def links
    party.links.map(&:to_liquid)
  end

  def phones
    party.phones.map(&:to_liquid)
  end
  
  %w(phones links addresses email_addresses).each do |model|
    %w(main home office fax cell mobile).each do |name|
      class_eval <<-EOF
        def #{name}_#{model}
          party.#{model}.#{name.pluralize}
        end
      EOF
    end
  end

  def addresses
    party.addresses.map(&:to_liquid)
  end

  def recent_posts
    party.recent_posts.map(&:to_liquid)
  end

  def feeds
    party.feeds.map(&:to_liquid)
  end

  def name
    party.name ? party.name.to_liquid : ""
  end
  
  def info_array
    titles = []
    party.info[:title].each_pair {|key, value| titles << [value, party.info[:body][key].to_s]} unless party.info.blank?
    titles
  end

  def ==(other)
    self.party == other.party
  end
  
  def main_phone
    self.party.main_phone.to_liquid
  end
  
  def main_email
    self.party.main_email.to_liquid
  end
  
  def main_link
    self.party.main_link.to_liquid
  end
  
  def main_address
    self.party.main_address.to_liquid
  end
  
  %w(pictures flash_files shockwave_files multimedia audio_files other_files).each do |method_name|
    self.class_eval <<-"end_eval"
      def #{method_name}
        self.party.#{method_name}.collect {|e| AssetDrop.new(e)}
      end
    end_eval
  end
  
  def before_method(method)
    if method.to_s =~ /^has_permission_(.*)/i
      return self.party.can?($1)
    end
    nil
  end
  
  def group_labels_to_s
    self.party.groups.map(&:label).join(",")
  end
  
  def affiliate_account_activated?
    return false unless self.party.has_affiliate_account?
    af = AffiliateAccountDomainActivation.find(:first, :conditions => {:domain_id => self.context['domain'].domain.id, :affiliate_account_id => self.party.affiliate_account_real_id})
    af ? true : false
  end  
end
