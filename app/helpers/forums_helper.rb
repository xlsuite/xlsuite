#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module ForumsHelper
  
  # used to know if a topic has changed since we read it last
  def recent_topic_activity(topic)
    return false if not current_user
    #return topic.replied_at > (session[:topics][topic.id] || last_active)
  end 
  
  # used to know if a forum has changed since we read it last
  def recent_forum_activity(forum)
    return false unless current_user && forum.topics.first
    #return forum.topics.first.replied_at > (session[:forums][forum.id] || last_active)
  end
end
