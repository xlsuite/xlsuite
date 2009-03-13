#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

# see the blogger API spec at http://www.blogger.com/developers/api/1_docs/
# note that the method signatures are subtly different to metaWeblog, they
# are not identical. take care to ensure you handle the different semantics
# properly if you want to support blogger API too, to get maximum compatibility.
#

module XMLRPC_Blog
  class Blog < ActionWebService::Struct
    member :url,      :string
    member :blogid,   :string
    member :blogName, :string
  end

  class User < ActionWebService::Struct
    member :nickname,  :string
    member :userid,    :string
    member :url,       :string
    member :email,     :string
    member :lastname,  :string
    member :firstname, :string
  end
  class GPost < ActionWebService::Struct
    #~ include XMLRPC
    member :postid,       :string
    #~ member :title, :string
    member :userid, :string
    member :authorName, :string
    member :lastModified,  :datetime
    member :dateCreated, :datetime
    member :postDate, :datetime
    member :url,        :string
    member :content, :string
    member :status,       :string
  end

# <member><name>postid</name><value>3595530104064751932-4552542455186435172</value></member>
# <member><name>url</name><value></value></member>
# <member><name>lastModified</name><value><dateTime.iso8601>20081003T13:03:52</dateTime.iso8601></value></member>
# <member><name>status</name><value>LIVE</value></member>
# <member><name>userid</name><value>644354351447</value></member>
# <member><name>content</name><value>Yesterday2 I had a peanut butter and pickle sandwich for lunch. Do you like . Please comment!</value></member>
# <member><name>authorName</name><value>userID: 644354351447firstName: 
# lastName: 
# email: akbett@gmail.com
# </value></member>
# <member><name>dateCreated</name><value><dateTime.iso8601>20080826T00:58:00</dateTime.iso8601></value></member>
# <member><name>postDate</name><value><dateTime.iso8601>20080826T00:58:00</dateTime.iso8601></value></member>


end

#
# blogger
#
class BloggerAPI < ActionWebService::API::Base
  inflect_names false

  api_method :deletePost, :returns => [:bool], :expects => [
    {:appkey=>:string},
    {:postid=>:string},
    {:username=>:string},
    {:password=>:string},
    {:publish=>:bool}
  ]

  api_method :newPost, :returns => [:string], :expects => [
    {:appkey=>:string},
    {:blogid=>:string},
    {:username=>:string},
    {:password=>:string},
    {:content=>:string},
    {:publish=>:bool}
  ]

  api_method :editPost, :returns => [:bool], :expects => [
    {:appkey=>:string},
    {:postid=>:string},
    {:username=>:string},
    {:password=>:string},
    {:content=>:string},
    {:publish=>:bool}
  ]

  api_method :getPost, :returns => [XMLRPC_Blog::GPost], :expects => [
    {:appkey=>:string},
    {:postid=>:string},
    {:username=>:string},
    {:password=>:string}
  ]

  api_method :getRecentPosts, :returns => [[XMLRPC_Blog::GPost]], :expects => [
     {:appkey=>:string},
     {:blogid=>:string},
     {:username=>:string},
     {:password=>:string},
     {:numberOfPosts=>:int}
   ]

  api_method :getUsersBlogs, :returns => [[XMLRPC_Blog::Blog]], :expects => [
    {:appkey=>:string},
    {:username=>:string},
    {:password=>:string}
  ]

  api_method :getUserInfo, :returns => [XMLRPC_Blog::User], :expects => [
    {:appkey=>:string},
    {:username=>:string},
    {:password=>:string}
  ]
end
