#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class EmailsController < ApplicationController
  extend ActionView::Helpers::SanitizeHelper::ClassMethods
  include ActionView::Helpers::SanitizeHelper
  
  required_permissions %w(async_get_page_urls async_get_tags async_get_searches async_get_template_label_id_hashes 
      async_send sandbox async_get_email async_get_mailbox_emails async_get_account_addresses sandbox_new async_destroy_collection update_west_console
      index conversations_with show_all_emails show_sent_and_read_emails show_unread_emails index new show reply reply_all forward save edit update release destroy async_mass_recipients_count) => "current_user?", 
   %w(create) => :send_mail

  before_filter :load_email, :only => %w(edit update reply reply_all forward release async_mass_recipients_count)
  with_options(:only => %w(new edit reply reply_all forward)) do |c|
    c.before_filter :get_email_addresses 
    c.before_filter :get_tags_and_groups_and_searches
  end
  
  def index
    respond_to do |format|
      format.js
      format.json do
        limit = params[:limit].to_i || 50
        start = params[:start].to_i || 0
        out = []
        total = 0

        imap_account = self.current_user.own_imap_account? ? self.current_user.own_imap_account : nil
        if imap_account
          break unless imap_account.enabled?
          imap = Net::IMAP.new(imap_account.connecting_server, imap_account.connecting_port)
          imap.login(imap_account.username, imap_account.password)
          total = imap.status("INBOX",["MESSAGES"])["MESSAGES"]
          examine = imap.examine('INBOX')
          latest_count = total - start
          earliest_count = latest_count - limit + 1
          earliest_count = 1 if earliest_count < 1
          @emails = imap.fetch(earliest_count..latest_count, ["ENVELOPE", "RFC822", "UID"]).map{|e| {:envelope => e.attr["ENVELOPE"], :rfc822 => e.attr["RFC822"], :uid => e.attr["UID"]}}.reverse
          from_string, imap_address, envelope = nil, nil, nil
          @emails.each do |email_attr|
            envelope = ImapEnvelope.new(email_attr[:envelope])
            tmail = TMail::Mail.parse(email_attr[:rfc822])
            out << {
              :id => email_attr[:uid],
              :from => envelope.from_name_or_address,
              :subject_with_body => (envelope.subject + " - " + ActionView::Helpers::TextHelper.truncate(self.strip_tags(tmail.html_or_plain_body.to_s), :length => 50)),
              :date => envelope.date.strftime("%b %d, %Y"),
              :mailbox => "inbox",
              :email_address => envelope.from_address
            }
          end
          imap.disconnect
        end
        render(:json => {:collection => out, :total => total}.to_json)
      end
    end
  end
  
  def show
    begin
      if params[:email_account_id]
        @email_account = EmailAccount.find(params[:email_account_id])
      else
        @email_account = self.current_user.own_imap_account
      end
      imap = Net::IMAP.new(@email_account.connecting_server, @email_account.connecting_port) 
      imap.login(@email_account.username, @email_account.password)
      imap.examine(params[:mailbox])
      @email = imap.uid_fetch(params[:id].to_i, ["ENVELOPE", "RFC822"]).first
      
      @envelope = ImapEnvelope.new(@email.attr["ENVELOPE"])
      
      @tmail = TMail::Mail.parse(@email.attr["RFC822"])
      @content = @tmail.html_or_plain_body
    ensure
      imap.disconnect
    end
    respond_to do |format|
      format.js
    end
  end
  
  def conversations_with
    raise StandardError, "Please include party_id as one of the parameters" unless params[:party_id]
    @target_party = self.current_account.parties.find(params[:party_id])
    @emails = self.current_user.email_conversations_with(@target_party)
    respond_to do |format|
      format.json do
        render(:json => {:collection => @emails, :total => @emails.size}.to_json)
      end
    end
  end

  def show_all_emails
    if current_user.can?(:edit_all_mailings)
      @record_emails = Email.find_users_emails(params[:ids], current_account)
    else
      @record_emails = Email.find_my_emails_with_users(params[:ids], current_account, current_user)
    end
    
    user_ids_arr = []
    params[:ids].split(',').map(&:strip).reject(&:blank?).each{|id| user_ids_arr << id.to_i} unless params[:ids].blank?
    
    @contact_requests = []
    
    if current_user.can?(:edit_contact_requests)
      @contact_requests = current_account.contact_requests.find(:all, :conditions => ["party_id IN (?) ", user_ids_arr])
      unless @contact_requests.blank?
        if @record_emails.blank?
          @record_emails = @contact_requests
        else
          j = 0
          @record_emails.each_index do |i|
            next if @record_emails[i].class == ContactRequest
            break if @record_emails.size >= 30
            email = @record_emails[i]
            if (email.sent_at || email.received_at) < @contact_requests[j].created_at
              @record_emails.insert(i, @contact_requests[j])
              j += 1
              break if j >= @contact_requests.size
            elsif i == @record_emails.size-1
              @record_emails.concat(@contact_requests.slice(j..@contact_requests.size))
              break
            end
          end
        end
      end
    end
    respond_to do |format|
      format.js do
        render(:json => {:string => render_to_string(:partial => "list_record_emails", :collection =>@record_emails)})
      end
    end
  end

  def show_unread_emails
    @email_count = current_user.count_unread_emails
    @emails = current_user.find_unread_emails({:limit => 30})
    respond_to do |format|
      format.js
    end
  end
  
  def show_sent_and_read_emails
    @emails = current_user.find_sent_and_read_emails({:limit => 30}) 
    respond_to do |format|
      format.js
    end
  end
  
  def async_get_page_urls
    urls = current_account.pages.map(&:to_url)
    urls.unshift "/admin/opt-out/unsubscribed"
    urls.unshift "/admin/opt-out"
    
    i = -1
    records = urls.collect { |url| { 'url' => url, 'id' => i += 1 } }
    wrapper = {'total' => records.size, 'collection' => records}
    
    render :json => wrapper.to_json
  end
  
  def sandbox_new
    @tags = current_account.parties.tags(:limit => 100, :order => "count desc")
    @all_tags = []
    @all_tags = Tag.find(:all, :group => "name", :order => "name") if current_superuser? && current_user.can?(:send_to_account_owners)
    @page_urls = current_account.pages.map(&:to_url)

    
    @mass = params[:mass] ? true : false
    
    if @mass
      @email = current_account.emails.build(
        :current_user => current_user,
        :domain => current_domain,
        :inline_attachments => false,
        :mass_mail => true
      )
    else 
      @email = current_account.emails.build(:current_user => current_user, :inline_attachments => true)
    end
    
    if params[:listing_ids]
      listing_urls = ""
      listing_path = "#{current_domain.name}/#{current_domain.get_config(:listing_show_path)}"
      listing_path.gsub!(/\/+/,"/")
      listing_path = "http://" + listing_path
      params[:listing_ids].split(',').map(&:strip).each{|id| listing_urls << "<li>#{listing_path.sub("__ID__", id)}</li>\n"}
      @email.body = "Listings that may interest you: \n<ul>#{listing_urls}</ul>\n\n"
    end
    if params[:order_uuid]
      template = current_account.templates.find_by_label(current_domain.get_config("send_order_template"))
      order = current_account.orders.find_by_uuid(params[:order_uuid])
      @email.body = template.body.gsub("__UUID__", order.uuid).gsub("__TOTAL__", order.total_amount.to_s).gsub("__SUBTOTAL__", order.subtotal_amount.to_s)
      @email.subject = template.subject
      @disable_template = @disable_opt_out = true
      @template_label = "Send Order"
      @mass = true
      params[:email_tos] = [order.invoice_to.respond_to?(:main_email) ? order.invoice_to.main_email.email_address : order.email.email_address]
    end
    @to_name_addresses_array = params[:to_name_addresses] ? params[:to_name_addresses].split(',') : []
    @to_name_addresses_array << params[:email_tos].split(',') if params[:email_tos]
    @email.subject ||= params[:subject]
    @domains = current_account.domains
    
    respond_to do |format|
      format.js
      format.html
    end
  end
    
  def async_get_mailbox_emails
    search_options = {:offset => params[:start], :limit => params[:limit], :order => "updated_at DESC"}
    search_options.merge!(:order => "#{params[:sort]} #{params[:dir]}") if params[:sort]
    query_params = params[:q]
    unless query_params.blank? 
      query_params = query_params.split(/\s+/)
      query_params = query_params.map {|q| q+"*"}.join(" ")
    end
    
    mailboxes = %w(inbox outbox draft sent)
    records = []
    label_records = []

    total_records_count = 0
    
    if mailboxes.include? params[:mailbox]
      records = current_user.send("find_#{params[:mailbox]}_emails", query_params, search_options)
      total_records_count += current_user.send("count_#{params[:mailbox]}_emails", query_params)
    end
    
    if current_user.email_labels.collect{|label| label.name}.include? params[:mailbox]
      label_records = current_user.email_labels.find_by_name(params[:mailbox]).find_emails
    end
    
    truncated_records = self.truncate_records(records)
    wrapper = { 'total' => total_records_count, 'collection' => truncated_records }
   
    render :json => wrapper.to_json
  end
  
  def async_get_email
    @email = Email.find params[:id]
    @email.read_by(current_user)
    render :partial => 'show', :layout => false, :locals => {:mailboxName => params[:mailbox]}
  end
  
  def sandbox
    if params[:id]
      # If :id is specified, the page will load the email
      # with the specified id right after the page loads via
      # the handy callback property of the resultSet
      @email_id = params[:id]
    end
    
    @mailbox = params[:mailbox] || 'inbox'
    
    @email_to_open = params[:email_to_open]
    
    respond_to do |format|
      format.js
    end
    #render :partial => 'sandbox', :layout => false
  end
  
=begin
  def index
    @mailboxNames = %w(inbox outbox draft sent)
  
    if params[:folder] =~ /sent/i
      @emails = current_user.find_sent_emails
    elsif params[:folder] =~ /outbox/i
      @emails = current_user.find_outbox_emails
    elsif params[:folder] =~ /draft/i
      @emails = current_user.find_draft_emails
    else
      @emails = current_user.find_inbox_emails
    end
    
    items_per_page = params[:show] || ItemsPerPage
    items_per_page = @emails.size if params[:show] =~ /all/i
    items_per_page = items_per_page.to_i
    
    @pager = ::Paginator.new(@emails.size, items_per_page) do |offset, limit|
      @emails[offset..offset+limit]
    end
    
    @page = @pager.page(params[:page])
    @emails = @page.items
    respond_to do |format|
      format.html
      format.json do
        render(:text => JsonCollectionBuilder::build(@emails))
      end
      format.xml { render(:text => current_user.find_unread_emails({:limit => 30}).to_xml.sub("<emails>", "<emails total='#{@emails.size}'>")) }
    end
  end
=end

=begin
  def show
    respond_to do |format|
      format.html do
        @email.read_by(current_user)
      end
      format.js do
        @unread_emails = current_user.find_unread_emails({:limit => 30})
        @unread_emails_count = current_user.count_unread_emails
        @sent_and_read_emails = current_user.find_sent_and_read_emails({:limit => 30}) 
        render(:action => "update_west_console.rjs")
      end
    end
  end
=end
  
  def update_west_console
    @unread_emails = current_user.find_unread_emails({:limit => 30})
    @unread_emails_count = current_user.count_unread_emails
    @sent_and_read_emails = current_user.find_sent_and_read_emails({:limit => 30}) 
    respond_to do |format|
      format.js
      format.html
    end
  end
  
  def new
    @email = current_account.emails.build(:current_user => current_user, :inline_attachments => true)
    @email.tos = params[:email_tos] || ''
  end
  
  # create and send the newly created email
  def create
    scheduled_at = params[:email].delete(:scheduled_at)
    Email.transaction do
      @sender = params[:email].delete(:sender)
      @sender = current_user if @sender.blank?

      @email = Email.create!(params[:email].merge(:current_user => current_user, :account => current_account, :sender => @sender))

      hour = params[:scheduled_at][:hr].to_i
      hour += 12 if params[:scheduled_at][:ampm] =~ /PM/
      scheduled_at = scheduled_at.utc.change(:hour => hour, :min => params[:scheduled_at][:min]) if scheduled_at.respond_to?(:utc)

      @email.scheduled_at = scheduled_at
      add_attachments

      @email.tag_list = @email.tag_list << ' sent'
      @email.release!

      flash_success :now, "Mail sent to #{@email.total_number_of_recipients} recipients"

      respond_to do |format|
        format.js do 
          render :json => {:success => true, :flash => flash[:notice].to_s, :id => @email.id}.to_json
        end
      end
    end
  rescue ActiveRecord::RecordInvalid
    logger.debug {$!.message + "\n\n" + $!.backtrace.join("\n")}
    render :json => {:success => false, :error => $!.record.errors.full_messages}.to_json
  rescue
    logger.debug {$!.message + "\n\n" + $!.backtrace.join("\n")}
    flash_failure :now, $!.message
    render :json => {:success => false, :error => $!.message}.to_json
  end
  
  def save
    scheduled_at = params[:email].delete(:scheduled_at)
    Email.transaction do
      @sender = params[:email].delete(:sender)
      @sender = current_user if @sender.blank?

      if params[:id]
        @email = current_account.emails.find(params[:id])
        @email.update_attributes!(params[:email].merge(:current_user => current_user, :account => current_account, :sender => @sender))
      else
        @open_new_edit_tab = true
        @email = Email.create!(params[:email].merge(:current_user => current_user, :account => current_account, :sender => @sender))
      end
      
      hour = params[:scheduled_at][:hr].to_i
      hour += 12 if params[:scheduled_at][:ampm] =~ /PM/
      scheduled_at = scheduled_at.utc.change(:hour => hour, :min => params[:scheduled_at][:min]) if scheduled_at.respond_to?(:utc)

      @email.scheduled_at = scheduled_at
      @email.save!
      params[:id] = @email.id
      add_attachments

      flash_success :now, "Mail saved as *draft*"
      @draft = true
      
      @preview = false
      if params[:preview] && @email.mass_mail?
        @preview = true
        @future = MethodCallbackFuture.create!(:models => [@email], :account =>  @email.account, :owner => current_user,
            :method => :generate_mass_recipients, :result_url => email_recipients_path(@email))
      end
      
      respond_to do |format|
        format.js
      end
    end
  rescue ActiveRecord::RecordInvalid
    logger.debug {$!.message + "\n\n" + $!.backtrace.join("\n")}
    render :json => {:success => false, :error => $!.record.errors.full_messages}.to_json
  rescue
    logger.debug {$!.message + "\n\n" + $!.backtrace.join("\n")}
    flash_failure :now, $!.message
    render :json => {:success => false, :error => $!.message}.to_json
  end
  
  def edit
    @domains = current_account.domains
    respond_to do |format|
      format.html {render}
      format.js
    end
  end

  def update
    Email.transaction do
      @sender = params[:email].delete(:sender)
      @sender = current_user if @sender.blank?
      
      @email.attachments.destroy_all if @email.attachments
      @email.attributes = params[:email].merge(:current_user => current_user, :account => current_account, :sender => @sender)
      @email.save!

      add_attachments

      @email.tag_list = @email.tag_list.gsub("draft", "")
      @email.tag_list = @email.tag_list << ' sent'
      @email.release!
      flash_success "Mail sent to #{@email.total_number_of_recipients} recipients"
      
      respond_to do |format|
        format.js do
          render :json => {:success => true, :id => @email.id, :flash => flash[:notice].to_s}.to_json
        end
      end
    end
  rescue
    logger.debug {$!.message + "\n\n" + $!.backtrace.join("\n")}
    flash_failure :now, $!.message
    render :json => {:success => false, :error => $!.message}.to_json
  end

  def reply
    @email = @email.reply(current_user)
    render :action => "new"
  end

  def reply_all
    @email = @email.reply_to_all(current_user)
    render :action => "new"
  end

  def forward
    @email = @email.forward(current_user)
    render :action => "new"
  end

  def release
    Email.transaction do
      @email.clear_recipients_and_attachments
      @email.attributes = params[:email]
      if @email.save
        #params[:attachments].each do |index, attrs|
        #  email_to_send.create_attachment!(attrs)
        #end
        @email.tag_list = @email.tag_list.gsub("draft", "")
        @email.tag_list = @email.tag_list << ' sent'
        @email.release!
        flash_success "Mail sent to #{@email.total_number_of_recipients} recipients"
        redirect_to emails_path(:folder => "outbox")
      else
        @email.save(false)
        flash_failure @email.errors.full_messages
        redirect_to edit_email_path(@email)
      end
    end
  end

  def destroy
    @email = current_user.emails.find(params[:id])
    unless @email.sender.id == current_user.id
      redirect_to new_session_url
      return
    end
    @email.destroy
    flash_success "Draft successfully removed."
    redirect_to emails_path(:folder => "draft")
  end

  def async_destroy_collection
    destroyed_items_size = 0
    current_account.emails.find(params[:ids].split(",").map(&:strip)).to_a.each do |email|
      destroyed_items_size += 1 if email.destroy
    end

    render :text => "#{destroyed_items_size} email(s) successfully deleted"
  end
  
  def async_get_account_addresses
    email_accounts = self.current_user.all_smtp_accounts
    address_ids = email_accounts.collect { |email_account| {'address' => email_account.username, 'id' => email_account.id.to_s } }
    if self.current_user.email_addresses.count > 0 && address_ids.size == 1
      self.current_user.email_addresses.each do |email_address|
        address_ids << {"address" => email_address.email_address, "id" => email_accounts.first.id} unless email_address.email_address == email_accounts.first.username
      end
    end
    wrapper = {'total' => address_ids.size, 'collection' => address_ids}
    respond_to do |format|
      format.js do 
        render(:json => wrapper.to_json, :status => 200)
      end
    end
  end
  
  def async_get_template_label_id_hashes
    templates = current_account.templates.find_all_accessible_by(current_user, :order => 'label ASC')
    records = []
    records = templates.collect { |template| { 'name' => "#{template.label} - #{template.subject}", 'id' =>  template.id.to_s, 'subject' => template.subject, 'body' => template.body } }
    wrapper = { 'total' => records.size, 'collection' => records }
   
    render :json => wrapper.to_json
  end
  
  def async_get_tags
    tags = current_account.parties.tags
    records = tags.collect { |tag| { 'name' => tag.name, 'id' => tag.id.to_s } }
    wrapper = {'total' => records.size, 'collection' => records}
    
    render :json => wrapper.to_json
  end
   
  def async_get_searches
    searches = current_user.searches.find(:all, :order => "name ASC")
    records = searches.collect { |search| { 'name' => search.name, 'id' => search.id.to_s } }
    wrapper = {'total' => records.size, 'collection' => records}

    render :json => wrapper.to_json
  end
  
  def async_mass_recipients_count
    render :json => {:count => @email.mass_recipients.size}.to_json
  end
  
protected
  def check_own_access
    redirect_to new_session_url unless current_user.has_access_to_email?(@email)
  end

  def get_email_addresses
    @email_addresses = current_user.email_addresses.find(:all, :order => 'email_address ASC')
  end

  def get_tags_and_groups_and_searches
    @tags = current_account.tags.find(:all, :order => "name ASC")
    @groups = current_account.groups.find(:all, :order => "name ASC")
    @searches = current_user.searches.find(:all, :order => "name ASC")
  end

  def load_email
    @email = current_account.emails.find(params[:id])
    @email.current_user = current_user
    check_own_access
  end

  def render_action_new
    @email = current_account.emails.build(:current_user => current_user)
    @email.attributes = params[:email]
    get_email_addresses
    get_tags_and_groups_and_searches
    render :action => "new"
  end
   
  def truncate_records(emails)
    truncated_records = []
    emails.each do |email|  
      # email is the full set of data, but we only want
      # id, subject, received_at, created_at, sender.id, sender.name
      to_names = email.tos.collect { |sender| sender.name }
      truncated_record = {
        'id' => email.id,
        'subject' => email.subject,
        'received_at' => email.received_at.to_s,
        'created_at' => email.created_at.to_s,
        'released_at' => email.released_at.to_s,
        'updated_at' => email.updated_at.to_s,
        'scheduled_at' => email.scheduled_at.to_s,
        'sent_at' => email.sent_at.to_s,
        'sender_id' => email.sender ? email.sender.id : 0,
        'sender_name' => email.sender ? email.sender.name : "Unknown",
        'sender_address' => email.sender ? email.sender.address : "Unknown",
        'party_id' => email.sender ? email.sender.party_id : 0,
        'to_names' => to_names.class == Array ? to_names.join(', ') : to_names
      }
      truncated_records.push truncated_record
    end
    return truncated_records
  end

  def add_attachments
    logger.debug {"==> Processing attachments #{params[:attachments].inspect}"}
    (params[:attachments] || []).reject {|attrs| attrs[:uploaded_data].blank?}.each do |att_attrs|
      asset = current_account.assets.create!(att_attrs.merge(:owner => current_user))
      @email.assets << asset
    end
    if params[:asset_ids]
      assets = self.current_account.assets.find(params[:asset_ids].split(",").map(&:strip).map(&:to_i))
      @email.assets << assets
    end
    logger.debug {"==> Done processing attachments"}

    logger.debug {"==> Processing assets #{params[:files].inspect}"}
    (params[:files] || []).reject {|attrs| attrs[:filename].blank?}.each do |attrs|
      @email.assets << current_account.assets.find_by_filename(attrs[:filename])
    end
    logger.debug {"==> Done processing assets"}

    logger.debug {"==> Processing assets #{params[:assets].inspect}"}
    (params[:assets] || []).reject {|attrs| attrs[:id].blank?}.each do |attrs|
      @email.assets << current_account.assets.find(attrs[:id])
    end
    logger.debug {"==> Done processing assets"}
  end
end
