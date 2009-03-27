#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "xl_suite/inline_form_builder"

module ApplicationHelper
  include DatePickerHelper
  include JavascriptEscaper
  include ExtjsHelper
  
  DOMAIN_PATTERNS_GUIDE_URL = "http://ixld.com/blogs/training/2009/2/14/multi-domain-management/3282"

  # Returns a JavaScript literal value, used to return variables in JS code (while doing #to_json)
  def jslit(value)
    JsonLiteral.new(value)
  end

  def render_forum_name(user)
    return "Unknown" if user.blank?
    name = user.profile.display_name if user.profile
    name = name || user.display_name
    link_to_function(name, "")
  end
  
  def render_textile_help_box
    html = ""
    html << '<div class="userInstr">'
    html << '<p>Use <a href="http://www.textism.com/tools/textile/" target="_blank">textile</a> formatting:</p>'
    html << '<ul id="formatHints">'
    html << '<li><u>To Format Text:</u><ul>'
    html << '<li class="italic">&nbsp;&nbsp;__italic__</li>'
    html << '<li class="bold">&nbsp;&nbsp;**bold**</li></ul></li>'
    html << '<li><u>Text Link:</u><ul><li>&nbsp;&nbsp;"example":www.example.com</li></ul></li>'
    html << '<li><u>Image: </u><ul><li>&nbsp;&nbsp;!www.mysite.com/myimage!</li></ul></li>'
    html << '</ul>'
    html << '<br/></div>'
  end
  
  def render_object_timestamps(object)
    out = []
    if object.respond_to?(:creator_name)
      content = []
      content << "Record created by"
      content << content_tag(:span, object.creator_name.blank? ? "Anonymous" : object.creator_name, :class => "created-by-name")
      content << "on"
      content << content_tag(:span, current_user.format_utc_date(object.created_at), :class => 'created-by-date')
      content << "at"
      content << content_tag(:span, current_user.format_utc_time(object.created_at), :class => 'created-by-time')
      out << content_tag(:p, content.join(" "), :class => "record-status")
    end
    
    if object.respond_to?(:editor_name) && !object.editor_name.blank?
      content = []
      content << "This page was last modified by"
      content << content_tag(:span, object.editor_name, :class => "modified-by-name")
      content << "on"
      content << content_tag(:span, current_user.format_utc_date(object.updated_at), :class => 'modified-by-date')
      content << "at"
      content << content_tag(:span, current_user.format_utc_time(object.updated_at), :class => 'modified-by-time')
      out << content_tag(:p, content.join(" "), :class => "record-status")
    end

    out.join("")
  end

  def javascript_include_ui
    params_clone = params.dup
    params_clone.delete("action")
    params_clone.delete("controller")
    path = [controller.controller_name, controller.action_name]
    ui_path = path.dup
    ui_path[-1] = ui_path.last + "_ui"
    template_path = File.join(File.dirname(__FILE__) + "/../views", *ui_path)
    template_path << ".rhtml"
    return unless File.exist?(template_path)
    content_tag(:script, "", :type => "text/javascript",
        :src => ui_path(params_clone.merge(:path => (path - %w(index)))))
  end

  def label(text, object, method, html_options={})
    attrs = {:for => "#{object}_#{method}"}
    attrs.merge!(html_options)
    text = text.to_s
    content_tag('label', text + (':' == text[-1,1] ? '' : ':'), attrs) +  "&nbsp;"
  end

  def display(object, method, html_options={})
    obj = instance_eval("@#{object}")
    value = obj.send(method)
    content_tag('span', h(value), {:id => "#{object}_#{method}"}.merge(html_options))
  end

  def image_link(options={})
    link_to(image_tag("tab_#{options[:id]}.gif",
              :size => options[:size], :alt => options[:alt],
              :id => options[:id], :name => options[:id]),
            options[:url], {
                :onmouseover => "MM_swapImage('#{options[:id]}','','#{image_path('tab_' + options[:id] + '_over.gif')}',1)",
                :onmouseout => 'MM_swapImgRestore()'})
  end

  def format_date(obj, default='&nbsp;')
    obj ? obj.strftime('%b %d, %Y') : default
  end

  def format_time(obj, default='&nbsp;')
    obj ? obj.strftime('%I:%M %p') : default
  end

  def format_date_and_time(obj, default='&nbsp;')
    obj ? obj.strftime('%b %d, %Y %I:%M %p') : default
  end
  alias_method :format_date_time, :format_date_and_time 

  def format_money(*args)
    obj = args.shift
    if args.last.kind_of?(Hash) then
      options = {:default => '0.00', :delimiter => '&nbsp;', :precision => 2}.merge(args.last)
    else
      options = {:default => args.shift || '0.00', :delimiter => args.shift || '&nbsp;'}
    end

    return obj.to_s unless obj.kind_of?(Money)
    return options[:default] if obj.zero?
    options[:unit] = '' unless options[:unit]
    number_to_currency(obj.cents / 100.0, options)
  end

  def text_field(object, method, options={})
    options[:autocomplete] = 'off' if options[:autocomplete].blank?
    super(object, method, options)
  end

  def date_field(object, method, options={})
    date_options = Hash.new
    date_options[:dateSeparator] = options.delete(:dateSeparator)
    date_options[:dateFormat] = options.delete(:dateFormat)
    obj = instance_eval("@#{object}")
    value = obj.send(method)
    text_field(object, method, {:size => 10}.merge(options)) + ' ' + date_picker_field_tag("#{object}_#{method}", format_date(value, ''), {:auto_field => false}.merge(date_options))
  end

  def text_field_tag(name, value, options={})
    options[:autocomplete] = 'off' if options[:autocomplete].blank?
    super(name, value, options)
  end

  def submit_tag(*args)
    args << {} unless args.last.kind_of?(Hash)
    if request.env['HTTP_USER_AGENT'] =~ /msie/i
      args.last[:onclick] = "buttonWorkaround(this, '#{args[0]}', 'form');"
    end

    or_option = args.last.delete(:or)

    args.last[:class] = "#{args.last[:class]} submit".strip
    returning "" do |out|
      out << super(*args)
      out << " <span class='button_or'>or " + or_option + "</span>" if or_option
    end
  end

  def flash_movie(name, options={})
    filename = name + '.swf'
    class_name = %Q{ class="#{options[:class]}"} if options[:class]
    options[:bgcolor] ||= '#000000'
    width = options[:width] || (options[:size] && options[:size].split('x')[0]) || nil
    height = options[:height] || (options[:size] && options[:size].split('x')[1]) || nil
    style = %Q{ style="width: #{width}px;"} if width

    <<EOF
<div#{class_name}#{style}>
  <object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"
          codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,0,0"
          #{"width=\"#{width}\"" if width} #{"height=\"#{height}\"" if height} id="#{name}">
    <param name="movie" value="#{image_path(filename)}"/>
    <param name="quality" value="high"/>
    <param name="LOOP" value="true"/>
    <param name="bgcolor" value="#{options[:bgcolor]}"/>
    <embed src="#{image_path(filename)}" quality="high" bgcolor="#{options[:bgcolor]}"
        #{"width=\"#{width}\"" if width} #{"height=\"#{height}\"" if height} name="#{name}"
        type="application/x-shockwave-flash"
        pluginspage="http://www.macromedia.com/go/getflashplayer">
    </embed>
  </object>
</div>
EOF
  end

  def windows_media_movie(name)
    filename = name + '.wmv'
    <<EOF
<div class="house" style="width: 320px; margin: 1em auto;">
  <object id="#{name}" width="320" height="285"
    classid="CLSID:22D6f312-B0F6-11D0-94AB-0080C74C7E95"
    standby="Loading Windows Media Player components..."
    type="application/x-oleobject">
    <param name="autoStart" value="True"/>
    <param name="filename" value="#{image_path(filename)}"/>
    <embed type="application/x-mplayer2"  src="#{image_path(filename)}"
      name="MediaPlayer" width="320" height="285"/>
  </object>

</div>
EOF
  end

  def file_size(filename)
    File.size(File.join(RAILS_ROOT, 'public', filename + '.wmv')) rescue 0
  end

  def form_table(*args)
    <<EOF
#{form_tag(*args)}
<table class="form" border="0" cellspacing="0" cellpadding="0" align="left" width="100%">
  <tbody>
EOF
  end

  def form_display_field(*args)
    %Q(<tr><td>#{label(*args[0..2])}</td><td>#{display(*args[1..-1])}</td></tr>)
  end

  def form_text_field(*args)
    %Q(<tr><td>#{label(*args[0..2])}</td><td>#{text_field(*args[1..-1])}</td></tr>)
  end

  def form_text_area(*args)
    %Q(<tr><td>#{label(*args[0..2])}</td><td>#{text_area(*args[1..-1])}</td></tr>)
  end

  def form_password_field(*args)
    %Q(<tr><td>#{label(*args[0..2])}</td><td>#{password_field(*args[1..-1])}</td></tr>)
  end

  def form_select_field(*args)
    %Q(<tr><td>#{label(*args[0..2])}</td><td>#{select(*args[1..-1])}</td></tr>)
  end

  def form_file_field(*args)
    %Q(<tr><td>#{label(*args[0..2])}</td><td>#{file_field(*args[1..-1])}</td></tr>)
  end

  def form_check_box(*args)
    %Q(<tr><td colspan="2"><label>#{check_box(*args[1..-1])} #{h(args[0])}</label></td></tr>)
  end

  def form_submit(*args)
    %Q(<tr><td colspan="2">#{submit_tag(*args)}</td></tr>)
  end

  def form_close(*args)
    <<EOF
  </tbody>
</table>
</form>
EOF
  end

  alias_method :start_form_table, :form_table
  alias_method :end_form_table, :form_close

  def link_to_when_can(*args)
    if current_user? && current_user.can?(args.last) then
      link_to *args[0...-1]
    else
      args[0]
    end
  end
  
  def link_to_remote_when_can(*args)
    if current_user? && current_user.can?(args.last) then
      link_to_remote *args[0...-1]
    else
      args[0]
    end
  end
  

  def text_area_with_auto_complete(object, method, tag_options={}, completion_options={})
    (completion_options[:skip_style] ? "" : auto_complete_stylesheet) +
    text_area(object, method, tag_options) +
    content_tag("div", "", :id => "#{object}_#{method}_auto_complete", :class => "auto_complete") +
    auto_complete_field("#{object}_#{method}", { :url => { :action => "auto_complete_for_#{object}_#{method}" } }.update(completion_options))
  end

  def labelled_form_for(*args, &proc)
    args << Hash.new unless args.last.kind_of?(Hash)
    options = args.last
    options.merge!(:builder => LabellingFormBuilder)
    form_for(*args, &proc)
  end

  def labelled_fields_for(object_name, *args, &proc)
    options = args.last.kind_of?(Hash) ? args.pop : Hash.new
    options[:builder] = LabellingFormBuilder
    args << options
    fields_for(object_name, *args, &proc)
  end

  def truncate(text, length=30)
    return "" if text.blank?
    super.gsub(/\s*&[^;]*(?=\.{3}$)/, '')
  end

  def format_value(value)
    case value
    when Money
      format_money(value)
    when Date
      format_date(value)
    when DateTime, Time
      format_date_time(value)
    else
      h(value.to_s)
    end
  end

  def variable_click_row(target, variable, description)e
    function = link_to_function("{{ #{variable} }}", %Q(appendVarToBody('#{target}', "var_#{variable}")), :id => "var_#{variable}", :class => 'var')
    content_tag(:td, function, :class => 'var') + content_tag(:td, description)
  end

  def throbber_id_for(record)
    "#{dom_id(record)}_throbber"
  end

  def throbber_for(record, options={})
    throbber(throbber_id_for(record), options)
  end

  def throbber(id=nil, options={})
    options[:class] ||= ""
    options[:class] += " throbber"
    options[:class].strip!

    image_tag('throbber.gif', options.reverse_merge(:id => id, :size => '16x16',
        :alt => 'AJAX request in progress', :style => 'display:none'))
  end

  def ajax_spinner_for(id, spinner="spinner.gif")
    "<img src='/images/#{spinner}' style='display:none; vertical-align:middle;' id='#{id.to_s}_spinner'> "
  end

  def avatar_for(user, size=32)
    image_tag "http://www.gravatar.com/avatar.php?gravatar_id=#{MD5.md5(user.email)}&rating=PG&size=#{size}", :size => "#{size}x#{size}", :class => 'photo'
  end

  def feed_icon_tag(title, url)
    (@feed_icons ||= []) << { :url => url, :title => title }
    link_to image_tag('feed-icon.png', :size => '14x14', :alt => "Subscribe to #{title}"), url
  end

  def format_text(text)
    white_list(RedCloth.new(auto_link(text.to_s)).to_html)
  end

  def search_posts_title
    returning (params[:q].blank? ? 'Recent Posts' : "Searching for '#{h params[:q]}'") do |title|
      title << " by #{h User.find(params[:user_id]).display_name}" if params[:user_id]
      title << " in #{h Forum.find(params[:forum_id]).name}"       if params[:forum_id]
    end
  end

  def search_posts_path(rss = false)
    options = params[:q].blank? ? {} : {:q => params[:q]}
    options[:format] = 'rss' if rss
    [[:user, :user_id], [:forum, :forum_id]].each do |(route_key, param_key)|
      return send("#{route_key}_posts_path", options.update(param_key => params[param_key])) if params[param_key]
    end
    all_posts_path(options)
  end

  def distance_of_time_in_words(from_time, to_time = 0, include_seconds = false)
    from_time = from_time.to_time if from_time.respond_to?(:to_time)
    to_time = to_time.to_time if to_time.respond_to?(:to_time)
    distance_in_minutes = (((to_time - from_time).abs)/60).round

    case distance_in_minutes
      when 0..1           then (distance_in_minutes==0) ? 'a few seconds ago' : '1 minute ago'
      when 2..59          then "#{distance_in_minutes} minutes ago"
      when 60..90         then "1 hour ago"
      when 90..1440       then "#{(distance_in_minutes.to_f / 60.0).round} hours ago"
      when 1440..2160     then '1 day ago' # 1 day to 1.5 days
      when 2160..2880     then "#{(distance_in_minutes.to_f / 1440.0).round} days ago" # 1.5 days to 2 days
      else from_time.strftime("%b %e, %Y  %l:%M%p").gsub(/([AP]M)/) { |x| x.downcase }
    end
  end

  def link_to_party(party, options={})
    return unless party
    text = options.delete(:text) || party.name.to_s
    link_to(h(text), general_party_path(party))
  end

  def link_to_recipient_email(recipient, options={})
    text = options.delete(:text) || h(recipient.subject)
    link_to(text, read_email_url(:id => recipient.id, :email => recipient.email.id),
        :icon => 'email_open.png') if recipient
  end

  def link_to_estimate(estimate, options={})
    return unless estimate
    name = estimate.customer.display_name if estimate.customer
    text = options.delete(:text) || name
    text = '<em>Anonymous</em>' if text.blank?
    link_to_when_can(text, estimate_edit_url(:id => estimate.id),
        {:title => 'Edit', :icon => 'brick_edit.png'}, [:edit_estimate])
  end

  def link_to_invoice(invoice)
    link_to_when_can(invoice.number, invoice_url(:id => invoice.number), {:icon => 'coins.png'}, :view_invoice)
  end

  def link_to_forum_post(post, options={})
    return unless post
    link_to(h(truncate(post.body, 60)), all_post_path(post.id), options.reverse_merge(:title => h(truncate(post.body, 240))))
  end

  def link_to_mass_email(email, options={})
    return unless email
    link_to(h(truncate(email.subject, 60)), mass_email_path(email.id), options.reverse_merge(:title => h(email.subject)))
  end

  def link_to_forum_topic(topic, options={})
    return unless topic
    link_to(h(truncate(topic.title, 60)), topic_path(topic.forum_category.id, topic.forum_id, topic.id), options.reverse_merge(:title => h(topic.title)))
  end

  def link_to_layout(layout, options={})
    return unless layout
    link_to(h(truncate(layout.title)), layout_path(layout.id), options)
  end

  def link_to_target(target)
    return unless target
    send("link_to_#{target.class.name.underscore}", target)
  end

  def link_to_attachment(attachment)
    return unless attachment
    link_to(h(attachment.title), unsecured_download_url(:id => attachment.id),
        :icon => attachment.icon_name)
  end

  def link_to_email(email)
    return unless email
    link_to(h(email.subject), mailing_edit_url(:id => email.id), :icon => 'email_edit.png')
  end

  def link_to_invoice_pdf(invoice)
    return unless invoice
    link_to(invoice.number, invoice_url(:id => @invoice.number, :format => 'pdf'), :icon => 'page_white_acrobat.png')
  end

  def link_to_contact_request(contact_request)
    return unless contact_request
    link_to(h(contact_request.subject), contact_request_path(contact_request))
  end

  def link_to_payment(payment)
    return unless payment
    link_to(format_date(payment.updated_at), payment_edit_url(:id => payment), :icon => 'money.png')
  end
  alias_method :link_to_paypal_payment, :link_to_payment 
  alias_method :link_to_credit_card_payment, :link_to_payment
  alias_method :link_to_check_payment, :link_to_payment 
  alias_method :link_to_cash_payment, :link_to_payment
  alias_method :link_to_other_payment, :link_to_payment

  def link_to_picture(picture, options={})
    return unless picture
    link_to(image_tag(picture_url(:id => @estimate.picture),
        options.reverse_merge(:size => Configuration.get(:customer_estimate_picture_geometry))),
        picture_view_url(:id => picture.id))
  end

  def link_to_product(product)
    return unless product
    link_to_when_can(h(product.no), product_edit_url(:id => product.id), :edit_catalog)
  end

  def link_to_product_category(product_category)
    return unless product_category
    link_to_when_can(h(product_category.name), product_category_edit_url(:id => product_category.id), :edit_catalog)
  end

  def link_to_link(link)
    return unless link
    link_to link.title, url_for(:controller => 'links', :action => 'edit', :id => link.id), :icon => "link.png"
  end
  
  def link_to_feed(feed)
    return unless feed
    link_to feed.owner.display_name, url_for(:controller => 'feeds', :action => 'edit', :id => feed.id), :icon => 'feed.png'
  end
  
  def format_value(value)
    case value
    when Date
      format_date(value)
    when DateTime, Time
      format_date_time(value)
    else
      value.to_s
    end
  end

  def link_to_group(group)
    return unless group
    url = if current_user? && current_user.can?(:edit_groups) then
      edit_group_path(group)
    else
      group_path(group)
    end

    link_to(h(group.name), url, :icon => "group")
  end

  def link_to_permission_set(permission_set)
    return unless permission_set
    url = if current_user? && current_user.can?(:edit_roles) then
      edit_permission_set_path(permission_set)
    else
      permission_set_path(permission_set)
    end

    link_to(h(permission_set.name), url)
  end

  def link_to_page(page)
    return unless page
    link_to(h(page.title), page_path(page), :icon => "page")
  end

  def typed_dom_id(object, *types)
    "#{dom_id(object)}_#{types.flatten.map(&:to_s).join("_")}"
  end

  def ext_form_for(*args, &proc)
    options = args.last.kind_of?(Hash) ? args.pop : Hash.new
    options[:builder] = XlSuite::ExtFormBuilder
    args << options
    form_for(*args, &proc)
  end

  def ext_fields_for(*args, &proc)
    options = args.last.kind_of?(Hash) ? args.pop : Hash.new
    options[:builder] = XlSuite::ExtFormBuilder
    args << options
    fields_for(*args, &proc)
  end

  def inline_form_for(*args, &proc)
    options = args.last.kind_of?(Hash) ? args.pop : Hash.new
    options[:builder] = XlSuite::InlineFormBuilder
    options[:html] ||= {}
    options[:html][:id] ||= dom_id(args[1] || instance_variable_get("@#{args.first}"))
    args << options
    form_for(*args, &proc)
  end

  def inline_remote_form_for(*args, &proc)
    options = args.last.kind_of?(Hash) ? args.pop : Hash.new
    options[:builder] = XlSuite::InlineFormBuilder
    options[:html] ||= {}
    options[:html][:id] ||= dom_id(args[1] || instance_variable_get("@#{args.first}"))
    args << options
    remote_form_for(*args, &proc)
  end

  def inline_fields_for(*args, &proc)
    options = args.last.kind_of?(Hash) ? args.pop : Hash.new
    options[:builder] = XlSuite::InlineFormBuilder
    args << options
    fields_for(*args, &proc)
  end
  
  def advanced_search_auto_complete_list
    AdvancedSearch::get_auto_complete_list.inspect
  end
  
  def process_show_and_page_params_from_uri(uri, show, page, input_options = {})
    default_options = {:overwrite_show => true, :overwrite_page => true}
    options = default_options.merge(input_options)
    uri = uri.gsub(/(&)?page=(\d)+/, "") if options[:overwrite_page]
    uri = uri.gsub(/(&)?show=((\d)+|all)/, "") if options[:overwrite_show]
    unless uri.index("?")
      uri << "?"
    end
    uri << "&show=#{show}" if !show.blank? && options[:overwrite_show]
    uri << "&page=#{page}" if !page.blank? && options[:overwrite_page]
    return uri
  end
  
  def process_sort_params_from_uri(sort)
    uri = request.request_uri
    uri = uri.gsub(/(&)?sort=[^&]+/, "")
    unless uri.index("?")
      uri << "?"
    end
    if uri.index("page=")
      uri = uri.gsub(/(&)?page=(\d)+/, "")
      uri << "&page=1" if !sort.blank?
    end
    uri << "&sort=#{sort}" if !sort.blank?
    return uri
  end

  def generate_links_of_paginator_pages(page, input_options = {})
    default_options = {:window_size => 2, :link_to_current_page => false, :dot_size => 3}
    options = default_options.merge(input_options)
    html_options = options.delete(:html)
    num_of_pages = page.pager.number_of_pages
    request_uri = request.request_uri
    return "" if num_of_pages <= 1
    current_page = page.number
    html = ""
    from = current_page - options[:window_size].to_i
    to = current_page + options[:window_size].to_i
    from = 1 if from < 1
    to = num_of_pages if to > num_of_pages
    if from != 1
      html << link_to("1", process_show_and_page_params_from_uri(request_uri, nil, 1, :overwrite_show => false), html_options)
    end
    if ((from - 1) > 1)
      html << " #{'.'*options[:dot_size].to_i} "
    end
    for e in from..to
      if e != current_page
        html << link_to(e, process_show_and_page_params_from_uri(request_uri, nil, e, :overwrite_show => false), html_options)
      else
        html << (options[:link_to_current_page] ? link_to(e, process_show_and_page_params_from_uri(request_uri, nil, e, :overwrite_show => false), html_options) : e.to_s)
      end
      html << " "
    end
    if to < num_of_pages - 1 
      html << " #{'.'*options[:dot_size].to_i} "
    end
    if to != num_of_pages 
      html << link_to(num_of_pages.to_s, process_show_and_page_params_from_uri(request_uri, nil, num_of_pages, :overwrite_show => false), html_options)
    end
    return html
  end  

  def cached_javascript_include_tag(*sources)
    html = javascript_include_tag(*sources)
    return html if sources.length == 1 || (sources.length == 2 && sources.last.kind_of?(Hash))

    cached_asset_name = generate_cached_asset(:javascripts, html)
    options = sources.last.kind_of?(Hash) ? sources.last : Hash.new
    javascript_include_tag(cached_asset_name, options)
  end

  def cached_stylesheet_link_tag(*sources)
    html = stylesheet_link_tag(*sources)
    return html #if sources.length == 1 || (sources.length == 2 && sources.last.kind_of?(Hash))

    cached_asset_name = generate_cached_asset(:stylesheets, html)
    options = sources.last.kind_of?(Hash) ? sources.last : Hash.new
    stylesheet_link_tag(cached_asset_name, options)
  end

  def generate_cached_asset(asset_type, html)
    RAILS_DEFAULT_LOGGER.debug {"cached_asset: Original HTML was:\n--START\n#{html}\n--END\n"}
    asset_extension = case asset_type
    when :stylesheets
      ".css"
    when :javascripts
      ".js"
    else
      raise ArgumentError, "Expected asset_type to be :javascripts or :stylesheets but was: #{asset_type.inspect}"
    end

    assets = html.scan(/(?:src|href)=(['"])(.+?)\?\d+\1/).map {|a| a.last}
    cached_asset_name = Digest::MD5.hexdigest(assets.join(",")) + asset_extension
    cache_root = File.join(RAILS_ROOT, "public", asset_type.to_s.pluralize, "cache")
    cached_asset_path = File.join(cache_root, cached_asset_name)

    RAILS_DEFAULT_LOGGER.debug {"cached_asset: Joining assets #{assets.inspect} into #{cached_asset_name}"}

    ensure_cached_asset_folder_exists!(cache_root)

    asset_mtimes = assets.map do |asset|
      File.mtime(File.join(RAILS_ROOT, "public", asset))
    end

    return "cache/" + cached_asset_name if \
        File.exists?(cached_asset_path) && File.mtime(cached_asset_path) > asset_mtimes.max

    RAILS_DEFAULT_LOGGER.debug {"cached_asset: Regenerating cache for #{cached_asset_path}: #{assets.inspect}"}
    File.open(cached_asset_path, "wb+") do |f|
      assets.each do |asset|
        asset_path = File.join(RAILS_ROOT, "public", asset)

        f.write("/* #{asset} */\n")
        f.write(File.read(asset_path))
        f.write("\n")
      end
    end

    return "cache/" + cached_asset_name
  end

  def ensure_cached_asset_folder_exists!(cache_root, perms=0755)
    return if File.exists?(cache_root)

    RAILS_DEFAULT_LOGGER.debug {"cached_asset: Creating cache_root #{cache_root.inspect}, setting permissions to #{sprintf('%04o', perms)}"}
    FileUtils.mkdir_p(cache_root)
    FileUtils.chmod(perms, cache_root)
  end

  def paginator_on(page, options={})
    return if page.blank?
    render(:partial => "shared/paginator", :object => page.pager, :locals => {:page => page, :options => options})
  end

  def when_user_can(*permissions, &block)
    return nil unless current_user?
    return nil unless current_user.can?(permissions)
    concat(capture(&block), block.binding)
  end

  alias_method :when_user_can?, :when_user_can

  def flash_messages
    show_flash_messages(:id => "notifications", :textilize => true)
  end

  def progress_bar(*args)
    options = args.last.kind_of?(Hash) ? args.pop : Hash.new
    options.reverse_merge!(:id => "progress")
    options[:class] ||= ""
    options[:class] << " progress_bar"
    options[:class].strip!

    percent = args.shift || 0
    content_tag(:div, render(:partial => "shared/bar", :object => percent), options)
  end

  def hnbsp(value)
    value.blank? ? "&nbsp;" : h(value)
  end

  def tag_cloud(*args)
    options = args.last.kind_of?(Hash) ? args.pop : Hash.new
    object, tags = args

    case object
    when Symbol
      object_name = object.to_s
    when ActiveRecord::Base
      object_name = object.dom_id
    when NilClass
      object_name = "x_#{Time.now.to_i}"
    when Array, Enumerable
      object_name, tags = "x_#{Time.now.to_i}", object
    else
      raise ArgumentError, "Don't know how to process objects of type #{object.class.name} in \#tag_cloud"
    end

    case tags
    when Symbol
      tags = object.respond_to?(tags) ? object.send(tags) : []
    end

    options.merge!(:object_name => object_name, :tags => tags)
    render(:partial => "shared/tag_cloud", :locals => options)
  end

  def textilize(text)
    return nil if text.blank?
    RedCloth.new(text, [:filter_html, :filter_styles]).to_html
  end
  
  def email_datetime_format(time)
    return "" if time.nil?
    time.yday == Time.now.yday ? time.strftime("%a, %I:%M%p") : time.strftime("%b %d")
  end
  
  def clean_html(string)
    string.nil? ? "" : sanitize(h(string))
  end
  
  def gmap_url(query)
    "http://maps.google.com/maps?hl=en&q=#{CGI::escape(query)}"
  end
  
  def text_field_tag_with_auto_complete(id, initial_value, options={})
    url = options.delete(:url)
    after_update_function = options.delete(:after_update) || ""
    update_function = options.delete(:update) || ""
    text_field_id = id
    out = []
    out << text_field_tag(text_field_id, initial_value, options)
    out << throbber(text_field_id + "_throbber")
    out << content_tag(:div, "", :id => text_field_id + "_auto_complete", :class => 'auto_complete', :style => "display: none")
    
    javascript_code = %Q!
        new Ajax.Autocompleter(
          '#{text_field_id}', 
          '#{text_field_id + "_auto_complete"}', 
          '#{url}', 
          { 
            method:'get', paramName:'q',
            tokens:['\\n'],
            indicator: '#{text_field_id + "_throbber"}'
        !    
    javascript_code << ", afterUpdateElement: #{after_update_function}" unless after_update_function.blank?
    javascript_code << %Q!, updateElement: #{update_function}! \
      unless update_function.blank?

    javascript_code << "  })"
        
    out << javascript_tag(javascript_code)         
    out.join("")
  end
  
  def render_logo_url
    if @_parent_domain
      return @_parent_domain.get_config(:logo_url)
    end
    if current_account
      return current_account.get_config(:logo_url) || Configuration.get(:logo_url)
    end
    Configuration.get(:logo_url)
  end 

  def authorization_fields_for(object_type, options={})
    @available_groups ||= current_account.groups.find(:all, :order => "name")
    @object_type = object_type.to_s
    @object = instance_variable_get("@#{@object_type}")
    @class_name = options[:class]
    returning(render(:partial => "shared/authorizations")) do
      @object, @object_type, @class_name = nil
    end
  end
  
  def render_favicon_url
    url = current_account.get_config(:favicon_url) || Configuration.get(:favicon_url)

    returning(url) do
      url << ".png" unless url =~ /[.](?:png|jpe?g|ico|gif)$/
    end
  end 

  def account_domains
    current_account.domains.reject {|d| d.name.blank?}
  end

  def google_map_include_tag
    key = current_domain.get_config(:google_maps_api_key)
    return nil if key.blank?
    render(:partial => "shared/extjs_google_map", :locals => {:key => key})
  end

  
  def user_agreement_url(domain=Domain.find_by_name("xlsuite.com"))
    fullslug = (domain.get_config("user_agreement_fullslug") || "").split("/").reject(&:blank?).join("/") 
    return self.user_agreement_url(Domain.find_by_name("xlsuite.com")) if fullslug.blank? && domain.name !~ /^xlsuite\.com$/i
    url = "http://" + domain.name + "/" + fullslug
    url
  end
  
  def privacy_policy_url(domain=Domain.find_by_name("xlsuite.com"))
    fullslug = (domain.get_config("privacy_policy_fullslug") || "").split("/").reject(&:blank?).join("/")
    return self.privacy_policy_url(Domain.find_by_name("xlsuite.com")) if fullslug.blank? && domain.name !~ /^xlsuite\.com$/i 
    url = "http://" + domain.name + "/" + fullslug
    url
  end  
end
