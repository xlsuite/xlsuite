class InitializingPartyPointsFromBlogPosts < ActiveRecord::Migration
  def self.up
    author = nil
    BlogPost.all(:select => "author_id, domain_id, account_id").each do |blog_post|
      next if blog_post.author_id.blank? || blog_post.domain_id.blank?
      author = Party.find(blog_post.author_id)
      author.add_point_in_domain(250, Domain.find(blog_post.domain_id))
    end
    # adding first post on a domain point
    blog_posts = BlogPost.all(:select => "author_id, domain_id", :group => "author_id, domain_id")
    blog_posts.each do |blog_post|
      next if blog_post.author_id.blank? || blog_post.domain_id.blank?
      author = Party.find(blog_post.author_id)
      author.add_point_in_domain(250, Domain.find(blog_post.domain_id))
    end
  end

  def self.down
    author = nil
    BlogPost.all(:select => "author_id, domain_id, account_id").each do |blog_post|
      next if blog_post.author_id.blank? || blog_post.domain_id.blank?
      author = Party.find(blog_post.author_id)
      author.add_point_in_domain(-250, Domain.find(blog_post.domain_id))
    end
    # substracting first post on a domain point
    blog_posts = BlogPost.all(:select => "author_id, domain_id", :group => "author_id, domain_id")
    blog_posts.each do |blog_post|
      next if blog_post.author_id.blank? || blog_post.domain_id.blank?
      author = Party.find(blog_post.author_id)
      author.add_point_in_domain(-250, Domain.find(blog_post.domain_id))
    end
  end
end
