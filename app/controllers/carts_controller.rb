#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class CartsController < ApplicationController
  skip_before_filter :login_required
  required_permissions :none
    
  before_filter :load_cart
  before_filter :create_cart, :only => [:update, :buy]
  
  def update
    return redirect_to(params[:empty_cart_url]) if params[:empty_cart_url] && @cart.total_amount.zero?

    params[:cart][:invoice_to_attrs].merge!(:email => params[:cart][:email_attrs])

    Cart.transaction do      
      @cart.update_attributes!(params[:cart]) if params[:cart]
      @cart.send("set_tax_flags")
      @cart.save!
      params[:cart_line].reject {|h| h[:product_id].blank?}.each do |attrs|
        @cart.add_product(attrs)
      end if params[:cart_line]
    end

    redirect_to_return_to_or_back

    rescue
      if params[:error_return_to]
        redirect_to params[:error_return_to]
        return
      end
      redirect_to_return_to_or_back
  end
  
  def destroy
    @cart.destroy unless @cart.new_record?
    session[:cart_id] = @cart = nil
    flash_success "Your cart has been cleared"
    redirect_to_return_to_or_back
  end
  
  def checkout
    flash[:liquid] ||= {}
    flash[:liquid][:params] = params
    
    if params[:empty_cart_url] && @cart.total_amount.cents == 0
      return redirect_to(params[:empty_cart_url])
    end
    
    if params[:cart][:email_attrs][:email_address].blank?
      flash_failure "Email Address can't be blank"
      return redirect_to(params[:return_to]) if params[:return_to]
      return redirect_to(:back)
    end
    
    Cart.transaction do 
      params[:cart][:invoice_to_attrs].merge!(:email => params[:cart][:email_attrs])
      @cart.update_attributes!(params[:cart]) if params[:cart]
      @cart.send("set_tax_flags")
      @cart.invoice_to = current_account.parties.create! unless @cart.invoice_to
      @cart.add_routes_to_invoice_to!      
      @order = @cart.to_order!
      if session[AFFILIATE_IDS_SESSION_KEY]
        @order.affiliate_usernames = session[AFFILIATE_IDS_SESSION_KEY]
        @order.save!
      end
      @cart.destroy
      session[:cart_id] = @cart = nil
    end
    respond_to do |format|
      format.html do
        return redirect_to(params[:next].gsub(/__uuid__/i, @order.uuid)) if params[:next]
        return redirect_to(:back) if request.env["HTTP_REFERER"]
      end
      format.js do
        return render(:json => {:uuid => @order.uuid}.to_json)
      end
    end
    rescue
      errors = $!.message.to_s
      logger.warn(errors.inspect)
      logger.warn($!.backtrace.join("\n"))
      respond_to do |format|
        format.html do
          flash_failure errors
          return redirect_to_return_to_or_back_or_home
        end
        format.js do
          return render(:json => {:uuid => nil}.to_json)
        end
      end
  end
  
  def buy
    if params[:empty_cart_url] && @cart.total_amount.cents == 0
      return redirect_to(params[:empty_cart_url])
    end
    Cart.transaction do
      @cart.invoice_to = current_account.parties.create! unless @cart.invoice_to
      @cart.add_routes_to_invoice_to!      
      @order = @cart.to_order!
      @payment = @order.make_payment!(params[:payment_method])
      
      who = current_user? ? current_user : @cart.invoice_to
      return_url = params[:return_url].blank? ? "" : params[:return_url].gsub("__UUID__", @order.uuid)
      options = {:return => return_url.as_absolute_url(current_domain.name), 
        :cancel_return => params[:cancel_url].as_absolute_url(current_domain.name), :notify_url => ipn_url}
      result = @payment.start!(who, options)
      @cart.destroy
      case @payment.payment_method
      when "paypal"
        redirect_to result.first
      else
        render_within_public_layout
      end
    end
  end
  
  def from_estimate
    @estimate = current_account.estimates.find_by_uuid(params[:uuid])
    Estimate.transaction do
      @cart = @estimate.to_cart!
      line = @cart.lines.create!(:quantity => nil, :retail_price => nil, :description => "Copied from Estimate #{params[:uuid]}")
      @cart.downpayment_amount = [
          @estimate.products_amount * current_account.get_config(:estimate_supplies_percentage) / 100.0,
          @estimate.labor_amount * current_account.get_config(:estimate_labor_percentage) / 100.0
        ].sum(Money.zero("CAD"))
      @cart.save!
      session[:cart_id] = @cart.id
      redirect_to params[:cart_page] || "/products/cart"
    end
  end  
end
