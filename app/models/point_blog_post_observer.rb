#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PointBlogPostObserver < ActiveRecord::Observer
  observe :blog_post
  FIRST_BLOG_POST_CREATE = 500
  BLOG_POST_CREATE = 250

  def before_save(blog_post)
    return if blog_post.new_record?
    blog_post.instance_variable_set(:@_old_record, blog_post.class.find(blog_post.id))
  end

  # Add points to the new author and substract points from the old author
  def after_save(blog_post)
    old_record = blog_post.instance_variable_get(:@_old_record)
    new_author = blog_post.author
    old_author = nil
    old_author = old_record.author if old_record
    return unless new_author
    if new_author
      if old_author
        if old_author.id != new_author.id
          points = if BlogPost.count(:conditions => {:account_id => blog_post.account_id, :domain_id => blog_post.domain_id, :author_id => old_author.id}) == 0
            FIRST_BLOG_POST_CREATE
          else
            BLOG_POST_CREATE
          end
          old_author.add_point_in_domain(-points, blog_post.domain)
          points = if BlogPost.count(:conditions => {:account_id => blog_post.account_id, :domain_id => blog_post.domain_id, :author_id => blog_post.author_id}) > 1
            BLOG_POST_CREATE
          else
            FIRST_BLOG_POST_CREATE
          end
          new_author.add_point_in_domain(points, blog_post.domain)
        end
      else # The else block will get executed only if the blog post was a new record
        points = if BlogPost.count(:conditions => {:account_id => blog_post.account_id, :domain_id => blog_post.domain_id, :author_id => blog_post.author_id}) == 1
          FIRST_BLOG_POST_CREATE
        else
          BLOG_POST_CREATE
        end
        new_author.add_point_in_domain(points, blog_post.domain)
      end
    end
  end

  # Reduce points of the blog post author
  def after_destroy(blog_post)
    return unless blog_post.author
    points = if BlogPost.count(:conditions => {:account_id => blog_post.account_id, :domain_id => blog_post.domain_id, :author_id => blog_post.author_id}) > 0
      BLOG_POST_CREATE
    else
      FIRST_BLOG_POST_CREATE
    end
    blog_post.author.add_point_in_domain(-points, blog_post.domain)
  end
end
