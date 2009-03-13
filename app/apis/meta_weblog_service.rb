#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require 'meta_weblog_api'

class MetaWeblogService < ActionWebService::Base
  web_service_api MetaWeblogAPI

  def initialize( request = nil, params = nil )
#    @postid = 0
    @request = request 
    @params = params 
    @current_account = nil
  end
 #----------------------------------------------------------------------------------------------  
  def deletePost( post_id, user, pw,  publish)
    logger.debug { "MetaWeblog.deletePost id=#{post_id} user=#{user} pw=#{pw}, [#{publish}]" }

    load_current_domain_xmlrpc if @current_account == nil

    current_user = Party.authenticate_with_account_email_and_password!(
        @current_account, user, pw)

    blog_posts = @current_account.blog_posts.find(:all, :conditions => ["id=?", post_id] )

    blog_post = blog_posts[0];

    raise "Post for that id don't exist" if( blog_post == nil )

    #~ $stderr.puts "1111111111111111111111: #{blog_post.inspect}"
   current_user = Party.authenticate_with_account_email_and_password!(
        @current_account, user, pw)

#    destroyed = blog_post.destroy
    if( blog_post )
      blog_post.destroy
      true
    else
      raise "So post don't exist"
    end

  end  
#----------------------------------------------------------------------------------------------  

  def newPost(id, user, pw, struct, publish)
    logger.debug { "MetaWeblog.newPost id=#{id} user=#{user} pw=#{pw}, struct=#{struct.inspect} [#{publish}]" }

    load_current_domain_xmlrpc if @current_account == nil

    current_user = Party.authenticate_with_account_email_and_password!(
        @current_account, user, pw)

    blog_post = BlogPost.new
    if id
      blog = @current_account.blogs.find(id)
      blog_post.blog = @blog
    end

    today = DateTime.now;
#     @blog_post.published_at = "Fri Oct 03 12:00:00 +0300 2008" if publish
    blog_post.published_at = today.strftime("%a %b %d %H:%M:%S %Z %Y") if publish


    blog_post.title = struct.title
    blog_post.body = struct.description
    blog_post.link = struct.link
    blog_post.author_name = current_user.first_name
    blog_post.author = current_user

    blog_post.account_id = current_user.account_id; 
    blog_post.blog_id = id ;
    blog_post.author_id = current_user.account_id;
#    blog_post.created_at = today.strftime("%Y-%m-%d %H:%M:%S");
    blog_post.created_at = today.strftime("%a %b %d %H:%M:%S %Z %Y");
    blog_post.hide_comments = false;

#     $stderr.puts  "3333333333333 blog_post_create @blog_post: #{ blog_post.inspect } ";

     created = blog_post.save
     blog_post.id if created


  end
#----------------------------------------------------------------------------------------------  

  def editPost(post_id, user, pw, struct, publish)
    logger.debug {"MetaWeblog.editPost  id=#{post_id} user=#{user} pw=#{pw} struct=#{struct.inspect} [#{publish}]" }

    load_current_domain_xmlrpc if @current_account == nil

    current_user = Party.authenticate_with_account_email_and_password!(
        @current_account, user, pw)

    blog_posts = @current_account.blog_posts.find(:all, :conditions => ["id=?", post_id] )

    blog_post = blog_posts[0];

    raise "Post for that id don't exist" if( blog_post == nil )

    current_user = Party.authenticate_with_account_email_and_password!(
        @current_account, user, pw)

    if( publish ) 
      today = DateTime.now;
#     @blog_post.published_at = "Fri Oct 03 12:00:00 +0300 2008" if publish
      blog_post.published_at = today.strftime("%a %b %d %H:%M:%S %Z %Y") 
    else
      blog_post.published_at = nil;
    end

    blog_post.title = struct.title
    blog_post.body = struct.description
    blog_post.link = struct.link

    blog_post.editor = current_user
    updated = blog_post.save
     
  end

#----------------------------------------------------------------------------------------------  
  def getPost(post_id, user, pw)
    logger.debug { "MetaWeblog.getPost post_id: #{post_id}"}

    load_current_domain_xmlrpc if @current_account == nil

    current_user = Party.authenticate_with_account_email_and_password!(
        @current_account, user, pw)

    posts = @current_account.blog_posts.find(:all, :conditions => ["id=?", post_id] )
    
#    $stderr.puts "11111111: posts #{posts.inspect}"
    post_item = posts[0]

    raise "Post for that id don't exist" if( post_item == nil )


    post = XMLRPC_Blog::MWPost.new(

    :postid => post_item.id,
    :title => post_item.title,
    :userid => post_item.author_id,
    :dateCreated => post_item.created_at,

    :link => post_item.link,
    :description => post_item.body,
    :post_status => 'publish',

    :permaLink => post_item.permalink,
    :categories => 'Not defined',

    :mt_allow_comments => 1,
    :wp_author_id => post_item.author_id


#        :mt_excerpt => post_item.author_id,
#        :mt_text_more => post_item.author_id,
#        :mt_allow_pings => 1,
#        :mt_keywords => post_item.author_id,
#        :wp_slug => post_item.author_id,
#        :wp_author_display_name => post_item.author_id,
#        :date_created_gmt => post_item.created_at

      )
      
    if( post_item.published_at )
        post
      else
        nil
    end

  end
#----------------------------------------------------------------------------------------------  

  def getCategories(id, user, pw)
    logger.debug { "MetaWeblog.getCategories categories for #{user}" }
    
    load_current_domain_xmlrpc if @current_account == nil

    current_user = Party.authenticate_with_account_email_and_password!(
        @current_account, user, pw)

    cat = XMLRPC_Blog::Category.new(
      :description => 'Not defined',
      :htmlUrl     => '',
      :rssUrl      => '')
    [cat]
  end
#----------------------------------------------------------------------------------------------  
  def getRecentPosts(id, user, pw, num)
    logger.debug { "MetaWeblog.getRecentPosts recent #{num} posts for user: #{user} on blog id: #{id}" }
    
    load_current_domain_xmlrpc if @current_account == nil

    current_user = Party.authenticate_with_account_email_and_password!(
        @current_account, user, pw)

    posts = @current_account.blog_posts.find(:all, :conditions => ["blog_id=?", id], 
      :limit => num, :order => "created_at DESC" )
    
#    $stderr.puts "11111111: current_user #{current_user.inspect}"

#    $stderr.puts "2222222: posts #{posts.inspect}"


    return_posts = Array.new();
    for post_item in posts
      post = XMLRPC_Blog::MWPost.new(

       :postid => post_item.id,
       :title => post_item.title,
       :userid => post_item.author_id,
       :dateCreated => post_item.created_at,

       :link => post_item.link,
       :description => post_item.body,
       :post_status => 'publish',

       :permaLink => post_item.permalink,
       :categories => 'Not defined',

       :mt_allow_comments => 1,
       :wp_author_id => post_item.author_id

#        :mt_excerpt => post_item.author_id,
#        :mt_text_more => post_item.author_id,
#        :mt_allow_pings => 1,
#        :mt_keywords => post_item.author_id,
#        :wp_slug => post_item.author_id,
#        :wp_author_display_name => post_item.author_id,
#        :date_created_gmt => post_item.created_at


      )
      return_posts.push(post) if post_item.published_at 
    end

    return_posts

  end

#----------------------------------------------------------------------------------------------  
  def load_current_domain_xmlrpc
    if @request.host =~ /^w+\./
      @www_domain = Domain.find_by_name(@request.host)
      
      # if the www domain is not found, redirect to non-www version immediately
      unless @www_domain
        headers["Status"] = "301 Moved Permanently"
        return false
      end
      
      @current_domain = Domain.find_by_name_and_account_id(@request.host.gsub(/^w+\./,''), @www_domain.account_id)
      if @current_domain
        headers["Status"] = "301 Moved Permanently"
        return false
      end
    end
    
    @current_domain = Domain.find_by_name(@request.host, :include => :account, :conditions => "accounts.confirmation_token IS NOT NULL")
    
    if @current_domain && @params[:action] =~ /confirm|activate/i && @params[:controller] == "accounts" && !@params[:code].blank?
      @current_account = @current_domain.account
      return true
    end
    
    @current_domain = Domain.find_by_name(@request.host, :include => :account, :conditions => "accounts.confirmation_token IS NULL AND domains.activated_at IS NOT NULL")
    @current_domain = Domain.new(:name => @request.host) unless @current_domain
    if Object.const_defined?(:NewRelic) && !@current_domain.new_record? then
      NewRelic::Agent.add_request_parameters(:account_id => @current_domain.account.id, :domain_id => @current_domain.id, :domain_name => @current_domain.name)
    end
    @current_account = @current_domain.account
    return true unless @current_domain.new_record?

    # Domain does not exist, and we're probably trying to buy it now, go on
    return true if self.controller_path == "accounts" && 
      ((self.action_name == "new" && @request.get?) || (self.action_name == "create" && @request.post?))

    return false
  end

  def logger
    @@logger ||= RAILS_DEFAULT_LOGGER
  end
  
end
