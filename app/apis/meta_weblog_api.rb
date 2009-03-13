#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

# here lie structures, cousins of those on http://www.xmlrpc.com/metaWeblog
# but they don't necessarily the real world reflect
# so if you do, find that your client complains:
# please tell, of problems you suffered through
#

require 'action_web_service'

module XMLRPC_Blog

   class MWPost < ActionWebService::Struct

     member :postid, :string
     member :title, :string
     member :userid,        :string
     member :dateCreated,       :datetime

     member :link, :string
     member :description, :string
     member :post_status, :string

     member :permaLink, :string
     member :categories, :string

     member :mt_excerpt, :string
     member :mt_text_more, :string
     member :mt_allow_comments, :int
     member :mt_allow_pings, :int
     member :mt_keywords, :string
     member :wp_slug, :string
     member :wp_author_id, :string
     member :wp_author_display_name, :string
     member :date_created_gmt, :datetime

   end


#   <value><struct>
#   <member><name>dateCreated</name><value><dateTime.iso8601>20080825T08:08:12</dateTime.iso8601></value></member>
#   <member><name>userid</name><value><string>4840399</string></value></member>
#   <member><name>postid</name><value><string>1</string></value></member>
#   <member><name>description</name><value><string>Welcome to &lt;a href=&quot;http://wordpress.com/&quot;&gt;Wordpress.com&lt;/a&gt;. This is your first post. Edit or delete it and start blogging!</string></value></member>
#   <member><name>title</name><value><string>Hello world!</string></value></member>
#   <member><name>link</name><value><string>http://ordasoft.wordpress.com/2008/08/25/hello-world/</string></value></member>
#   <member><name>permaLink</name><value><string>http://ordasoft.wordpress.com/2008/08/25/hello-world/</string></value></member>
#   <member><name>categories</name><value><array><data>
#   <value><string>Uncategorized</string></value>
# </data></array></value></member>
#   <member><name>mt_excerpt</name><value><string></string></value></member>
#   <member><name>mt_text_more</name><value><string></string></value></member>
#   <member><name>mt_allow_comments</name><value><int>1</int></value></member>
#   <member><name>mt_allow_pings</name><value><int>1</int></value></member>
#   <member><name>mt_keywords</name><value><string></string></value></member>
#   <member><name>wp_slug</name><value><string>hello-world</string></value></member>
#   <member><name>wp_password</name><value><string></string></value></member>
#   <member><name>wp_author_id</name><value><string>4840399</string></value></member>
#   <member><name>wp_author_display_name</name><value><string>akbet</string></value></member>
#   <member><name>date_created_gmt</name><value><dateTime.iso8601>20080825T08:08:12</dateTime.iso8601></value></member>
#   <member><name>post_status</name><value><string>publish</string></value></member>
#   <member><name>custom_fields</name><value><array><data>
# </data></array></value></member>
# </struct></value>



  class Category < ActionWebService::Struct
    member :description, :string
    member :htmlUrl,     :string
    member :rssUrl,      :string
  end
end

#
# metaWeblog
#
class MetaWeblogAPI < ActionWebService::API::Base
  inflect_names false

  api_method :deletePost, :returns => [:bool], :expects => [
    {:postid=>:string},
    {:username=>:string},
    {:password=>:string},
    {:publish=>:bool}
  ]

  api_method :newPost, :returns => [:string], :expects => [
    {:blogid=>:string},
    {:username=>:string},
    {:password=>:string},
    {:struct=>XMLRPC_Blog::MWPost},
    {:publish=>:bool}
  ]

  api_method :editPost, :returns => [:bool], :expects => [
    {:postid=>:string},
    {:username=>:string},
    {:password=>:string},
    {:struct=>XMLRPC_Blog::MWPost},
    {:publish=>:bool},
  ]

  api_method :getPost, :returns => [XMLRPC_Blog::MWPost], :expects => [
    {:postid=>:string},
    {:username=>:string},
    {:password=>:string},
  ]

  api_method :getCategories, :returns => [[XMLRPC_Blog::Category]], :expects => [
    {:blogid=>:string},
    {:username=>:string},
    {:password=>:string},
  ]

  api_method :getRecentPosts, :returns => [[XMLRPC_Blog::MWPost]], :expects => [
     {:blogid=>:string},
     {:username=>:string},
     {:password=>:string},
     {:numberOfPosts=>:int}
   ]

end
