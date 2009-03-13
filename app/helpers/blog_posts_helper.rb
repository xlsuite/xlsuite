#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module BlogPostsHelper
  def set_active_tab
    out = []
    out << %Q`
      tabPanel.setActiveTab(#{self.generate_inside_tab_panel_id(:comments).to_json});
    ` if params[:open] =~ /^(comment|spam_comment)/i
    out << %Q`
      spamSelection.setValue("true");
      ds.load({params: {start: 0, limit: #{params[:limit] || 50}, blog_post_id: #{@blog_post.id}, spam: "true" }});
    ` if params[:open] =~ /^spam_comment/i
    
    return out.join("\n")
  end
end
