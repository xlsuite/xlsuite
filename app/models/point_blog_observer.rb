#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PointBlogObserver < ActiveRecord::Observer
  observe :blog
  BLOG_CREATE = 100
  
  def before_save(blog)
    blog.instance_variable_set(:@_old_record, blog.id ? blog.class.find(blog.id) : nil)
  end
  
  # Add points to the blog owner
  def after_create(blog)
    owner = blog.owner
    return unless owner
    owner.add_point_in_domain(BLOG_CREATE, blog.domain)
  end
  
  # Add points to the new owner and substract points from the old owner
  def after_save(blog)
    old_record = blog.instance_variable_get(:@_old_record)
    new_owner = blog.owner
    old_owner = old_record ? old_record.owner : new_owner
    return unless new_owner
    if new_owner
      if new_owner.id == old_owner.id
        # This means owner does not change
      else
        new_owner.add_point_in_domain(BLOG_CREATE, blog.domain)
      end
      if old_owner && (old_owner.id != new_owner.id)
        old_owner.add_point_in_domain(-BLOG_CREATE, blog.domain)
      end
    end
  end
  
  # Reduce points of the blog owner
  def after_destroy(blog)
    blog.owner.add_point_in_domain(-BLOG_CREATE, blog.domain) if blog.owner
    true
  end
end
