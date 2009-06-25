#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ProductsController < ApplicationController
  # check the authorized? method
  required_permissions :none
  
  before_filter :find_common_products_tags, :only => [:new, :edit, :display_info]
  before_filter :find_root_product_categories, :only => [:new, :edit, :display_info]
  before_filter :create_fake_root_product_category, :only => [:new, :edit, :display_info]
  before_filter :convert_price_params_to_money, :only => [:create, :update]
  
  before_filter :find_product, :only => [:async_get_main_image, :async_get_image_ids, :async_upload_image, :async_update,
    :edit, :update, :display_info, :discounts, :sale_events, :supply, :attach_assets, :detach_assets, :embed_code]
  
  def index
    respond_to do |format|
      format.html
      format.js
      format.json do
        find_products
        render(:json => {:total => @products_count, :collection => assemble_records(@products)}.to_json)
      end
    end
  end
  
  def new
    @product = current_account.products.build
    respond_to do |format|
      format.js
    end
  end
  
  def create
    @product = current_account.products.build(params[:product])
    @product.creator_id = self.current_user.id
    @product.current_domain = current_domain
    @created = @product.save
    if @created && params[:files].kind_of?(Hash)
      params[:files].each_pair do |key, value|
        asset = current_account.assets.build(value)
        asset.owner = self.current_user
        created = asset.save
        if created
          View.create(:asset => asset, :attachable => @product)
        end
      end
    end
    if !@created
      flash_failure :now, @product.errors.full_messages
    else
      flash_success :now, "Product #{@product.name} successfully created"
    end
    respond_to do |format|
      format.html do
        if @created
          if params[:next]
            params_next = params[:next]
            params_next.gsub!(/__id__/i, @product.id.to_s)
            return redirect_to(params_next)
          end
          return redirect_to(:back) if request.env["HTTP_REFERER"]
        else
          return redirect_to(params[:return_to]) if params[:return_to]
          return redirect_to(:back) if request.env["HTTP_REFERER"]
        end
      end
      format.js do
        if @created
          return render(:json => {:success => true, :id => @product.id}.to_json)
        else
          return render(:json => {:success => false}.to_json)
        end
      end
    end
  end
  
  def edit
    @formatted_comments_path = formatted_comments_path(:commentable_type => "Product", :commentable_id => @product.id, :format => :json)
    @affiliate_setup_lines_product_path = affiliate_setup_lines_path(:target_type => "Product", :target_id => @product.id)
    @affiliate_setup_line_product_path = affiliate_setup_line_path(:target_type => "Product", :target_id => @product.id, :id => "__ID__")
    @destroy_collection_affiliate_setup_lines_path = destroy_collection_affiliate_setup_lines_path(:target_type => "Product", :target_id => @product.id)
    @edit_comment_path = edit_comment_path(:commentable_type => "Product", :commentable_id => @product.id, :id => "__ID__")
    respond_to do |format|
      format.js
    end
  end
  
  def async_update
    if @product.writeable_by?(current_user)
      key = params[:product].keys[0] # Get the attribute we need
      
      if key.include? '_ids'
        # Split by commas, then make them all integers
        params[:product][key] = params[:product][key].split(',').collect(&:to_i)
      end
      @product.attributes = params[:product]
      @product.editor_id = current_user.id
      if params[:product].has_key?(:private)
        @product.private = false if @product.private =~ /false/i
      end
      @updated = @product.save
      if !@updated
        flash_failure :now, @product.errors.full_messages
      end
      
      if key.include? '_ids'
        @product = current_account.products.find(params[:id])
        return render(:json => @product.send(key).to_json)
      else
        return render(:json => @product.send(key).to_s.to_json)
      end
    end
  end
  
  def update_image_ids
    
  end
  
  def update
    if @product.writeable_by?(current_user)
      params_product = params[:product]
      if params_product[:category_ids]
        params_product[:category_ids] = params_product[:category_ids].split(",").map(&:strip).map(&:to_i)
      end
      @product.attributes = params_product
      @product.editor_id = current_user.id
      @updated = @product.save!
      if @updated && params[:files].kind_of?(Hash)
        params[:files].each_pair do |key, value|
          asset = current_account.assets.build(value)
          asset.owner = self.current_user
          created = asset.save
          if created
            View.create(:asset => asset, :attachable => @product)
          end
        end
      end
      if !@updated
        flash_failure :now, @product.errors.full_messages
        respond_to do |format|
          format.html do
            return redirect_to(params[:return_to]) if params[:return_to]
            return redirect_to(:back) if request.env["HTTP_REFERER"]
          end
          format.js
        end
      else
        respond_to do |format|
          format.html do
            return redirect_to(params[:next]) if params[:next]
            return redirect_to(:back) if request.env["HTTP_REFERER"]
          end
          format.js
        end
      end      
    end
  end
  
  def attach_assets
    @assets = []
    if params[:asset_ids]
      @assets = current_account.assets.find(params[:asset_ids].split(",").map(&:strip))
    elsif params[:files] && params[:files].kind_of?(Hash)
      params[:files].each_pair do |key, value|
        asset = current_account.assets.build(value)
        asset.owner = self.current_user
        created = asset.save
        if created
          @assets << asset
        end
      end
    else
      respond_to do |format|
        format.html do
          return redirect_to(params[:return_to]) if params[:return_to]
          return redirect_to(:back) if request.env["HTTP_REFERER"]
        end
        format.js do
          return render(:json => {:success => false}.to_json)
        end
      end
    end
    @assets.each do |asset|
      View.create(:asset => asset, :attachable => @product)
    end
    respond_to do |format|
      format.html do
        return redirect_to(params[:next]) if params[:next]
        return redirect_to(:back) if request.env["HTTP_REFERER"]
      end
      format.js do
        return render(:json => {:success => true, :ids => @assets.map(&:id)}.to_json)
      end
    end
  end
  
  def detach_assets
    asset_ids = params[:asset_ids].split(",").map(&:strip)
    views = @product.views.find(:all, :conditions => {:asset_id => asset_ids})
    
    if views.size != asset_ids.size
      respond_to do |format|
        format.html do
          flash_failure "One or more assets not related to the product"
          return redirect_to(params[:return_to]) if params[:return_to]
          return redirect_to(:back) if request.env["HTTP_REFERER"]
        end
        format.js do
          return render(:json => {:success => false, :ids => (asset_ids - views.map(&:asset_id))}.to_json)
        end
      end
    else
      views.map(&:destroy)
      respond_to do |format|
        format.html do
          return redirect_to(params[:next]) if params[:next]
          return redirect_to(:back) if request.env["HTTP_REFERER"]
        end
        format.js do
          return render(:json => {:success => true, :ids => @assets.map(&:id)}.to_json)
        end
      end
    end
  end
  
  def display_info
    respond_to do |format|
      format.js { render :action => "display_info", :layout => false }
    end
  end
  
  def discounts
    respond_to do |format|
      format.js { render :action => "discounts", :layout => false }
    end
  end

  def sale_events
    @sale_events = @product.sale_events
    respond_to do |format|
      format.json { render :text => JsonCollectionBuilder::build(@sale_events) }
    end
  end
  
  def supply
    respond_to do |format|
      format.js { render :action => "supply", :layout => false }
    end
  end
  
  def destroy_collection
    @destroyed_items_size = 0
    current_account.products.find(params[:ids].split(",").map(&:strip)).to_a.each do |product|
      next unless product.writeable_by?(current_user)
      @destroyed_items_size += 1 if product.destroy
    end
    
    flash_success :now, "#{@destroyed_items_size} product(s) successfully deleted"
    respond_to do |format|
      format.js
    end
  end
  
  def tagged_collection
    @tagged_items_size = 0
    current_account.products.find(params[:ids].split(",").map(&:strip)).to_a.each do |product|
      next unless product.writeable_by?(current_user)
      product.tag_list = product.tag_list + " #{params[:tag_list]}"
      @tagged_items_size += 1 if product.save
    end
    
    respond_to do |format|
      format.js do
        flash_success :now, "#{@tagged_items_size} products has been tagged with #{params[:tag_list]}"
      end
    end
  end
  
  # GET request
  # INPUTS:
  #   id - of the product
  # OUTPUTS:
  #   JSON like: {total: X, collection: [{url: 'http://whatever', id: X}]}
  def async_get_image_ids
    records = @product.image_ids.collect do |id|
      asset = current_account.assets.find id
      {
        :id => id,
        :url => download_asset_path(:id => id),
        :filename => asset.filename
      }
    end
  
    wrapper = {:total => records.length, :collection => records}
    render :json => wrapper.to_json
  end
  
  def async_get_main_image
    records = []
    
    if (@product.main_image)
      asset = current_account.assets.find @product.main_image_id
      records << {
        :id => asset.id,
        :url => download_asset_path(:id => asset.id),
        :filename => asset.filename
      }
    end
    
    wrapper = {:total => records.size, :collection => records}
    render :json => wrapper.to_json
  end
  
  # POST request
  # INPUTS:
  #   id - id of the product
  #   file - the file object
  # OUTPUTS:
  #   On success - {url: 'http://whatever', id: X}
  #   On failure - "Error 1, Error 2"
  def async_upload_image
    Account.transaction do
      @picture = current_account.assets.build(:filename => params[:Filename], :uploaded_data => params[:file])
      @picture.content_type = params[:content_type] if params[:content_type]
      @picture.save!
      @view = @product.views.create!(:asset_id => @picture.id)

      render :json => {:success => true, :message => 'Upload Successful!'}.to_json
    end

  rescue
    @messages = []
    @messages << @picture.errors.full_messages if @picture
    @messages << @view.errors.full_messages if @view
    logger.debug {"==> #{@messages.to_yaml}"}
    render :json => {:success => false, :error => @messages.flatten.delete_if(&:blank?).join(',')}.to_json
  end
  
  def destroy
    @destroyed = @product.destroy
    respond_to do |format|
      format.html do
        if @destroyed
          flash_success "#{@product.name} successfully deleted"
          return redirect_to(params[:next]) if params[:next]
          return redirect_to(:back) if request.env["HTTP_REFERER"]
        else
          flash_failure "Failed destroying #{@product.name}"
          return redirect_to(params[:return_to]) if params[:return_to]
          return redirect_to(:back) if request.env["HTTP_REFERER"]
        end
      end
      format.js do
        return render(:json => {:success => @destroyed}.to_json)
      end
    end    
  end

  def embed_code
    assigns = {"product" => ProductDrop.new(@product),"current_time" => Time.now,"domain" => DomainDrop.new(current_domain), 
            "account" => AccountDrop.new(current_account)}
    
    registers = {"account" => current_account, "domain" => current_domain}

    context = Liquid::Context.new(assigns, registers, false)
       
    if params[:asset_id]
      @asset = current_account.assets.find(params[:asset_id])
      if !current_account.snippets.find_by_title("product/embed_with_image")
        current_account.snippets.create!(:title => "product/embed_with_image", :body => %Q`
  <form method="post" action="http://{{domain.name}}/admin/cart_lines" name="buy_product_{{product.id}}_form">
  <div style="margin: 0pt; padding: 0pt; display: none;">
  <input id="quantity" type="hidden" value="1" name="cart_line[quantity]" size="2"/>
  <input type="hidden" value="{{product.id}}" name="cart_line[product_id]"/>
  <input type="hidden" name="return_to" value="http://{{domain.name}}/products/cart?added=1&id={{product.id}}"/>
  </div>
  <a href="javascript:document.getElementsByName('buy_product_{{product.id}}_form')[0].submit();">
  <img border="0" src="http://{{domain.name}}__asset_url__"/>
  </a>
  </form>
  `, :published_at => Time.now, :creator => current_user)
      end
      @embed_code = Liquid::Template.parse("{% render_snippet title:'product/embed_with_image' %}").render!(context)
      @embed_code = @embed_code.gsub("__asset_url__", @asset.image_url)
    else
      if !current_account.snippets.find_by_title("product/embed_default")
        current_account.snippets.create!(:title => "product/embed_default", :body => %Q`
  <form name="buy_product_{{product.id}}" action="http://{{domain.name}}/admin/cart_lines" method="post">
  <img src="http://{{domain.name}}{{ product.pictures.first.mini_src }}" />
  <input id="quantity" type="hidden" size="2" name="cart_line[quantity]" value="1"/>
  <input type="hidden" name="cart_line[product_id]" value="{{product.id}}"/>
  <input type="hidden" value="http://{{domain.name}}/products/cart?added=1&id={{product.id}}" name="return_to"/>
  <input type="submit" value="Buy"/>
  </form>
  `, :published_at => Time.now, :creator => current_user)
      end
      @embed_code = Liquid::Template.parse("{% render_snippet title:'product/embed_default' %}").render!(context)
    end
    respond_to do |format|
      format.js
    end
  end
  
  protected

  def find_common_products_tags
    @common_tags = current_account.products.tags(:order => "count DESC, name ASC")
  end
  
  def find_root_product_categories
    @root_categories = current_account.product_categories.roots
  end

  def create_fake_root_product_category
    @fake_root_category = current_account.product_categories.build(:name => 'Root')
    @fake_root_category.children << @root_categories
    @fake_root_category.freeze
  end
  
  def find_products
    search_options = {:offset => params[:start], :limit => params[:limit]}
    search_options.merge!(:order => "#{params[:sort]} #{params[:dir]}") if params[:sort]
    
    query_params = params[:q]
    unless query_params.blank? 
      query_params = query_params.split(/\s+/)
      query_params = query_params.map {|q| q+"*"}.join(" ")
    end

    @products_proxy = case params[:product_category_id]
    when nil
      current_account.products 
    when /^all$/i
      current_account.products
    when /^0$/
      ids = current_account.products.find(:all, 
        :joins => "INNER JOIN product_categories_products AS pcp ON pcp.product_id = products.id", 
        :select => :id).map(&:id)
        
      ids = [0] if ids.empty? 
      search_options.merge!(:conditions => "id NOT IN (#{ids.join(',')})")
      current_account.products
    else
      ProductCategory.find(params[:product_category_id]).products
    end

    if current_user.can?(:edit_catalog)
      @products = @products_proxy.search(query_params, search_options)
      search_options.delete(:order)
      search_options.delete(:limit)
      search_options.delete(:offset)
      @products_count = @products_proxy.count_results(query_params, search_options)
    else
      @products = @products_proxy.find_readable_by(current_user, query_params, search_options)
      search_options.delete(:order)
      search_options.delete(:limit)
      search_options.delete(:offset)
      @products_count = @products_proxy.count_readable_by(current_user, query_params)
    end
  end
  
  def find_product
    @product = current_account.products.find(params[:id])
  end
  
  def convert_price_params_to_money
    params[:product][:wholesale_price] = params[:product][:wholesale_price].to_money if params[:product][:wholesale_price]
    params[:product][:retail_price] = params[:product][:retail_price].to_money if params[:product][:retail_price]
  end
  
  def assemble_records(records)
    results = []
    records.each do |record|
      results << {
        :id => record.id,
        :object_id => record.dom_id,
        :name => record.name, 
        :most_recent_supplier_name => "", 
        :in_stock => record.in_stock,
        :on_order => record.on_order,
        :sold_to_date => record.sold_to_date,
        :wholesale_price => record.wholesale_price.to_s,
        :retail_price => record.retail_price.to_s,
        :margin => record.margin
      }
    end
    results
  end
   
  def authorized?
    if %w(index new create edit async_update display_info discounts sale_events supply destroy_collection tagged_collection embed_code).index(self.action_name)
      self.current_user?
    elsif %w(destroy update attach_assets detach_assets).index(self.action_name)
      return false unless self.current_user?
      return true if self.current_user.can?(:edit_products)
      self.find_product
      return true if @product.creator.id == self.current_user.id
      false
    elsif %w( update_image_ids async_get_image_ids async_get_main_image async_upload_image).index(self.action_name)
      true
    else
      false
    end
  end
end
