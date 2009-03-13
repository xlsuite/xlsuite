#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module SearchHelper
  def link_to_result(result)
    link_to(h(result.label), send(result.subject_type.underscore + "_path", result.subject_id))
    rescue
      link_to_target(result.subject)
  end

  def get_link_to_search_result(object)
    return "n/a" if object.blank?
    if object.respond_to?(:main_identifier)
      display_name = object.main_identifier.to_s.strip
      display_name = h(truncate(display_name, 60))
      display_name = "n/a" if display_name.blank?
    else
      display_name = "n/a"
    end
    link_to_display_name = send("link_to_search_result_#{object.class.name.underscore}", display_name, object) rescue display_name
    return link_to_display_name
  end

  def fill_in_contacts_column(object)
    search_result = !object.respond_to?("party") ? object : object.party
    return "<td>n/a</td>" if search_result.blank?
    routes = [search_result.contact_routes.phones + search_result.contact_routes.emails + search_result.contact_routes.links].flatten.reject(&:blank?)
    html = "<td>"
    html += "<ul class='inline routes'>"
    html += link_to_party(search_result, :text => strip_tags(render(:partial => "route", :collection => routes, :spacer_template => "shared/list_comma")).gsub("&#160;"," ") )
    html += "</ul></td>"
    html
  end

protected
  # link to base classes
  def link_to_search_result_contact_route(display_name, object)
    target = object.routable
    if target.class.name == "Party"
      return link_to(display_name, party_path(target.id), :class => 'searchResult')
    end
    display_name
  end
  
  def link_to_search_result_payment(display_name, object)
    link_to display_name, payment_edit_url(:id => object.id), :class => 'searchResult'
  end
  
  # link to implemented classes
  alias_method :link_to_search_result_address_contact_route, :link_to_search_result_contact_route  

  def link_to_search_result_assignee(display_name, object)
    link_to(display_name, todo_edit_url(object.event.id), :class => 'searchResult')
  end

  def link_to_search_result_attachment_authorization(display_name, object)
    link_to(display_name, attachment_path(object.attachment.id), :class => 'searchResult')
  end

  alias_method :link_to_search_result_cash_payment, :link_to_search_result_payment

  alias_method :link_to_search_result_check_payment, :link_to_search_result_payment 

  def link_to_search_result_comment_estimate_line(display_name, object)
    link_to(display_name, estimate_show_url(object.estimate.id), :class => 'searchResult')
  end
  
  def link_to_search_result_comment_invoice_line(display_name, object)
    link_to(display_name, invoice_url(object.invoice.id), :class => 'searchResult')
  end

  def link_to_search_result_contact_request_event(display_name, object)
    link_to(display_name, contact_request_path(object.contact_request.id), :class => 'searchResult')
  end

  def link_to_search_result_contact_request(display_name, object)
    link_to(display_name, contact_request_path(object.id), :class => 'searchResult')
  end

  alias_method :link_to_search_result_credit_card_payment, :link_to_search_result_payment
  
  def link_to_search_result_cursor_estimate_line(display_name, object)
    link_to(display_name, estimate_show_url(object.estimate.id), :class => 'searchResult')
  end

  def link_to_search_result_email_contact_route(display_name, object)
    link_to(display_name, "mailto:#{object.address}", :class => 'searchResult')
  end  

  def link_to_search_result_email_event(display_name, object)
    link_to display_name, read_mail_url(object.email.id), :class => 'searchResult'
  end

  def link_to_search_result_email(display_name, object)
    link_to display_name, read_mail_url(object.id), :class => 'searchResult'
  end

  # FIXME what's the url to be used?
  def link_to_search_result_employee(display_name, object)
    display_name
  end

  def link_to_search_result_estimate_event(display_name, object)
    link_to display_name, estimate_show_url(object.estimate.id), :class => 'searchResult'
  end

  def link_to_search_result_estimate_section(display_name, object)
    link_to display_name, estimate_show_url(object.estimate.id), :class => 'searchResult'
  end

  def link_to_search_result_estimate(display_name, object)
    link_to display_name, estimate_show_url(object.id), :class => 'searchResult'
  end

  def link_to_search_result_feed(display_name, feed)
    link_to display_name, feed.feed_url, :class => 'searchResult'
  end

  def link_to_search_result_forum_category(display_name, forum_category)
    link_to display_name, forum_category_path(forum_category), :class => 'searchResult'
  end
  
  def link_to_search_result_forum(display_name, forum)
    link_to display_name, forum_path(forum.forum_category, forum), :class => 'searchResult'
  end

  def link_to_search_result_forum_post(display_name, forum_post)
    link_to display_name, topic_path(forum_post.forum_category, forum_post.forum, forum_post.topic), :class => 'searchResult'
  end

  def link_to_search_result_forum_topic(display_name, forum_topic)
    link_to display_name, topic_path(forum_topic.forum_category, forum_topic.forum, forum_topic), :class => 'searchResult'
  end

  def link_to_search_result_invoice_event(display_name, object)
    link_to display_name, invoice_url(object.invoice.id), :class => 'searchResult'
  end

  def link_to_search_result_invoice(display_name, object)
    link_to display_name, {:controller => 'admin/invoices', :action => 'view2', :id => object.id}, :class => 'searchResult'
  end

  def link_to_search_result_layout(display_name, object)
    link_to display_name, layout_path(object.id), :class => 'searchResult'
  end

  def link_to_search_result_link_category(display_name, object)
    link_to display_name, links_url(object.id), :class => 'searchResult'
  end

  def link_to_search_result_link_contact_route(display_name, object)
    link_to display_name, object.url, :class => 'searchResult'
  end

  def link_to_search_result_link(display_name, object)
    link_to display_name, object.address, :class => 'searchResult'
  end

  def link_to_search_result_manhour_estimate_line(display_name, object)
    link_to display_name, estimate_show_url(object.estimate.id), :class => 'searchResult'
  end

  def link_to_search_result_manhour_invoice_line(display_name, object)
    link_to display_name, invoice_url(object.invoice.id), :class => 'searchResult'
  end

  alias_method :link_to_search_result_other_payment, :link_to_search_result_payment

  # FIXME page activerecord not found
  def link_to_search_result_page(display_name, object)
    link_to display_name, page_path(object.id), :class => 'searchResult'
  end

  def link_to_search_result_party_picture(display_name, object)
    link_to display_name, picture_view_url(object.picture.id), :class => 'searchResult'
  end

  def link_to_search_result_party(display_name, party)
    link_to display_name, party_path(party.id), :class => 'searchResult'
  end

  def link_to_search_result_payment_event(display_name, object)
    link_to display_name, payment_edit_url(:id => object.payment.id), :class => 'searchResult'
  end

  alias_method :link_to_search_result_paypal_payment, :link_to_search_result_payment 

  alias_method :link_to_search_result_phone_contact_route, :link_to_search_result_contact_route  

  def link_to_search_result_picture(display_name, object)
    link_to display_name, picture_view_url(object.id), :class => 'searchResult'
  end

  def link_to_search_result_product_category(display_name, object)
    link_to display_name, product_categories_url(object.id), :class => 'searchResult'
  end

  def link_to_search_result_product_estimate_line(display_name, object)
    link_to display_name, estimate_show_url(object.estimate.id), :class => 'searchResult'
  end

  def link_to_search_result_product_invoice_line(display_name, object)
    link_to display_name, invoice_url(object.invoice.id), :class => 'searchResult'
  end

  def link_to_search_result_product(display_name, object)
    link_to display_name, product_edit_url(object.id), :class => 'searchResult'
  end

  def link_to_search_result_recipient(display_name, object)
    link_to display_name, read_mail_url(object.email.id), :class => 'searchResult'
  end
  
  # FIXME what's the url to be used?
  def link_to_search_result_schedule(display_name, object)
    display_name
  end
  
  def link_to_search_result_search(display_name, object)
    link_to_remote display_name, :url => {:controller => 'search', :action => 'show_saved_search', :id => object.id}
  end

  # FIXME what's the url to be used?
  def link_to_search_result_tag(display_name, object)
    display_name
  end
  
  def link_to_search_result_testimonial(display_name, object)
    link_to display_name, party_path(object.party.id), :class => 'searchResult'
  end
  
  def link_to_search_result_todo_event(display_name, object)
    link_to display_name, todo_edit_url(object.id), :class => 'searchResult'
  end
end
