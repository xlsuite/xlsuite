class SetBlogRelatedPoints < ActiveRecord::Migration
  def self.up
    party = nil
    domain = nil
    Blog.all(:select => "owner_id, domain_id").each do |blog|
      party = Party.find_by_id(blog.owner_id)
      domain = Domain.find_by_id(blog.domain_id)
      return unless party && domain
      party.add_point_in_domain(100, domain)
    end
  end

  def self.down
    Blog.all(:select => "owner_id, domain_id").each do |blog|
      Party.find(blog.owner_id).add_point_in_domain(-100, Domain.find(blog.domain_id))
    end
  end
end
