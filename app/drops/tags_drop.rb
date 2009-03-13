#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class TagsDrop < Liquid::Drop
  def products
    @context.current_account.products.tags
  end
  
  def blogs
    @context.current_account.blogs.tags
  end
  
  def blog_posts
    @context.current_account.blog_posts.tags
  end
end
