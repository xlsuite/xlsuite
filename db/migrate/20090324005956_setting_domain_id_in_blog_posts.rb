class SettingDomainIdInBlogPosts < ActiveRecord::Migration
  def self.up
    Blog.all(:select => "id, domain_id").each do |blog|
      next unless blog.domain_id # some blogs do not have domain id because they are a suite's blogs
      BlogPost.update_all("domain_id = #{blog.domain_id}", "blog_id = #{blog.id}")
    end
  end

  def self.down
    BlogPost.update_all("domain_id = NULL")
  end
end
