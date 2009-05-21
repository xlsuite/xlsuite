#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class OrdersController < ApplicationController
  required_permissions %w(index show view) => [:view_orders, :edit_orders, {:any => true}],
    %w(new create edit update destroy tax_fields destroy_collection get_totals get_send_order_template) => :edit_orders
  skip_before_filter :login_required, :only => [:buy, :pay]
  before_filter :load_order, :only => %w(buy show edit update destroy tax_fields get_totals)
 
  def index
    search_options = {:offset => params[:start], :limit => params[:limit]}
    search_options.merge!(:order => params[:sort].blank? ? "date DESC, number DESC" : "#{params[:sort]} #{params[:dir]}") 
    unless params[:status].blank? || params[:status] =~ /all/i
      search_conditions = {:conditions => ["status LIKE ?", params[:status]]} 
      search_options.merge!(search_conditions)
    end

    query_params = params[:q]
    unless query_params.blank? 
      query_params = query_params.split(/\s+/)
      query_params = query_params.map {|q| q+"*"}.join(" ")
    end

    @orders = current_account.orders.search(query_params, search_options)
    @orders_count = current_account.orders.count_results(query_params, search_conditions || {})

    respond_to do |format|
      format.html
      format.js
      format.json do
        render(:json => {:total => @orders_count, :collection => assemble_records(@orders)}.to_json)
      end
    end
  end
  
  def new
    @order = current_account.orders.build
    @order.domain = self.current_domain
    @order.invoice_to = current_account.parties.find(params[:invoice_to_id]) if params[:invoice_to_id]

    @common_order_tags = current_account.orders.tags(:order => "count DESC, name ASC")
    respond_to do |format|
      format.js
    end
  end

  def create
    @order = current_account.orders.build(params[:order])
    @order.domain = self.current_domain
    if @order.save then
      @created = true
      flash_success :now, "Order \##{@order.number} successfully created"
    else
      flash_failure :now, @order.errors.full_messages.reject{|error| error =~ /Account|Payment can't be blank/i }
    end
    respond_to do |format|
      format.js
    end
    
    rescue
      flash_failure :now, "Please select an Invoice To and a Date"
  end
  
  def edit
    @send_order_path = sandbox_new_emails_path(:order_uuid => @order.uuid, :mass => true)
    @formatted_order_payments_path = formatted_payments_path({:subject_id => @order.id, :subject_type => "Order", :format => :json})
    @payments_path = payments_path({:subject_id => @order.id, :subject_type => "Order"})
    @payment_path = payment_path({:id => "__ID__"})
    @common_order_tags = current_account.orders.tags(:order => "count DESC, name ASC")
    respond_to do |format|
      format.js
    end
  end
  
  def update
    @old_subtotal = @order.subtotal_amount
    @old_total = @order.total_amount
    
    @order.update_attributes(params[:order])
    respond_to do |format|
      format.js do
        @updated = @order.ship_to ? @order.ship_to.update_attributes(params[:ship_to]) : @order.create_ship_to(params[:ship_to])
        if @order.ship_to
          recommended_shipping_fee = current_account.destinations.shipping_cost_for_country_and_state(@order.ship_to.country, @order.ship_to.state)        
          @recommend_msg = "Recommended shipping fee: #{recommended_shipping_fee.to_s}"
        end
        if @updated then
          flash_success :now, "Order \##{@order.number} successfully updated. "
        else
          flash_failure :now, @order.errors.full_messages
        end
      end
    end
  end
  
  def destroy_collection
    @destroyed_items_size = 0
    current_account.orders.find(params[:ids].split(",").map(&:strip)).to_a.each do |order|
      @destroyed_items_size += 1 if order.destroy
    end
    flash_success :now, "#{@destroyed_items_size} order(s) successfully deleted"
    respond_to do |format|
      format.js
    end
  end
  
  def auto_complete_tag
    @tags = current_account.folders.tags_like(params[:q])
    render_auto_complete(@tags)
  end
  
  def tax_fields
    respond_to do |format|
      format.js { render :action => "tax_fields", :layout => false }
    end
  end
  
  def get_totals
    respond_to do |format|
      format.js { render :json => json_get_totals_for(@order).to_json}
    end
  end
  
  def get_send_order_template
    send_order_config = current_domain.get_config("send_order_template")
    @send_order_template = current_account.templates.find_by_label(send_order_config) if send_order_config
    respond_to do |format|
      format.js { render :json => {:template_name => @send_order_template ? @send_order_template.label : nil}.to_json}
    end
  end
  
  def view
    send_order_config = self.current_domain.get_config("send_order_template")
    order_uuids = self.current_account.orders.find(params[:ids].split(",").map(&:strip).map(&:to_i)).map(&:uuid)
    @send_order_template = self.current_account.templates.find_by_label(send_order_config) if send_order_config
    view_url = nil
    if @send_order_template
      if @send_order_template.body =~ /(https?:\/\/.+\..+__uuid__.*)/i
        view_url = $1
        view_url = view_url.split("http").select{|e| e =~ /__uuid__/i}.last
        view_url = "http" + view_url
        @order_urls = []
        order_uuids.each do |uuid|
          @order_urls << view_url.gsub(/__uuid__/i, uuid)
        end
      end
    end
    respond_to do |format|
      format.js
    end
  end
  
  def pay
    ActiveRecord::Base.transaction do
      self.load_order_by_uuid
      @payment = @order.make_payment!(params[:payment_method])
      
      who = current_user? ? current_user : @order.invoice_to
      return_url = params[:return_url].blank? ? "" : params[:return_url].gsub(/__uuid__/i, @order.uuid)    
      case @payment.payment_method
      when "paypal"
        options = {:return => return_url.as_absolute_url(current_domain.name), :notify_url => ipn_url}
        options.merge!(:cancel_return => params[:cancel_url].gsub(/__uuid__/i, @order.uuid).as_absolute_url(current_domain.name)) if params[:cancel_url] 
        result = @payment.start!(who, options)
        redirect_to result.first
      when "credit_card"
        options = {:return => return_url.as_absolute_url(current_domain.name)}
        options.merge!(:credit_card => params[:credit_card], :domain => self.current_domain)
        result = @payment.start!(who, options)
        redirect_to return_url
      else
        render_within_public_layout
      end
    end
  rescue StandardError
    flash_failure $!.message
    if params[:error_return_to]
      redirect_to params[:error_return_to]
      return
    end
    redirect_to_return_to_or_back
  end
  
  def buy
    if params[:empty_cart_url] && @order.total_amount.cents == 0
      return redirect_to(params[:empty_cart_url])
    end
    Order.transaction do
      @payment = @order.make_payment!(params[:payment_method])
      
      who = current_user? ? current_user : @order.invoice_to
      return_url = params[:return_url].blank? ? "" : params[:return_url].gsub("__UUID__", @order.uuid)
      options = {:return => return_url.as_absolute_url(current_domain.name), 
        :cancel_return => params[:cancel_url].as_absolute_url(current_domain.name), :notify_url => ipn_url}
      result = @payment.start!(who, options)
      case @payment.payment_method
      when "paypal"
        redirect_to result.first
      else
        render_within_public_layout
      end
    end
  end  
  
  protected
  def assemble_records(records)
    results = []
    records.each do |record|
      results << {
        :id => record.id,
        :object_id => record.dom_id, 
        :number => record.number, 
        :date => record.date.to_s, 
        :shipping_method => record.shipping_method, 
        :status => record.status, 
        :care_of_name => record.care_of_name, 
        :created_by_name => record.created_by_name, 
        :updated_by_name => record.updated_by_name, 
        :sent_by_name => record.sent_by_name, 
        :confirmed_by_name => record.confirmed_by_name, 
        :completed_by_name => record.completed_by_name, 
        :subtotal => record.subtotal_amount.to_s, 
        :total => record.total_amount.to_s,
        :invoiced_to_name => record.invoice_to ? (record.invoice_to.full_name.blank? ? record.invoice_to.display_name : record.invoice_to.full_name) : ""
      }
    end
    results
  end
  
  def json_get_totals_for(order)
    {
      :subtotal => order.subtotal_amount.to_s, 
      :labor => order.labor_amount.to_s, 
      :products => order.products_amount.to_s, 
      :fst => order.fst_rate,
      :pst => order.pst_rate,
      :labor_fst => order.labor_fst_amount.to_s,
      :labor_pst => order.labor_pst_amount.to_s,
      :labor_total => [order.labor_fst_amount, order.labor_pst_amount, order.labor_amount].sum(Money.zero(order.total_amount.currency)).to_s,
      :products_fst => order.products_fst_amount.to_s,
      :products_pst => order.products_pst_amount.to_s,
      :products_total => [order.products_fst_amount, order.products_pst_amount, order.products_amount].sum(Money.zero(order.total_amount.currency)).to_s,
      :shipping => order.fees_amount.to_s,
      :shipping_fst => order.fees_fst_amount.to_s,
      :shipping_pst => order.fees_pst_amount.to_s,
      :shipping_total => [order.fees_amount, order.fees_fst_amount, order.fees_pst_amount].sum(Money.zero(order.total_amount.currency)).to_s,
      :total => order.total_amount.to_s
    }
  end
  
  def load_order_by_uuid
    @order = current_account.orders.find_by_uuid(params[:uuid])
  end
  
  private
  def load_order
    @order ||= current_account.orders.find(params[:id])
  end
end
