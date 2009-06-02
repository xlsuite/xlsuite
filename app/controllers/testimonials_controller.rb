#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class TestimonialsController < ApplicationController
  required_permissions :none
  
  def index
    respond_to do |format|
      format.js
      format.json do
        load_testimonials
        render :json => {:collection => assemble_records(@testimonials), :total => @testimonials_count}.to_json
      end
    end
  end

  def new
    @testimonial = current_account.testimonials.build
    respond_to do |format|
      format.js
    end
  end

  def create
    @testimonial = current_account.testimonials.build(params[:testimonial])
    @testimonial.created_by = current_user
    @testimonial.testified_at = Time.now.utc
    @created = @testimonial.save
    @close = true if params[:commit_type] && params[:commit_type] =~ /close/i
    respond_to do |format|
      format.js do
        self.render_json_response
      end
    end
  end

  def edit
    respond_to do |format|
      format.js
    end
  end

  def update
    @testimonial.attributes = params[:testimonial]
    @updated = @testimonial.save
    @close = true if params[:commit_type] && params[:commit_type] =~ /close/i
    respond_to do |format|
      format.js do
        flash_success(:now, "Testimonial is updated") if @updated 
        self.render_json_response
      end
    end
  end

  def destroy_collection
    @destroyed_items_size = 0
    @undestroyed_items_size = 0
    current_account.testimonials.find(params[:ids].split(",").map(&:strip)).each do |testimonial|
      if testimonial.writeable_by?(current_user)
        testimonial.destroy
        @destroyed_items_size += 1
      else
        @undestroyed_items_size += 1
      end
    end

    error_message = []
    error_message << "#{@destroyed_items_size} testimonial(s) successfully deleted" if @destroyed_items_size > 0
    error_message << "#{@undestroyed_items_size} testimonial(s) failed to be destroyed" if @undestroyed_items_size > 0

    flash_success :now, error_message.join(", ")
    respond_to do |format|
      format.js
    end
  end

  def approve_collection
    @approved_size = 0
    current_account.testimonials.find(params[:ids].split(",").map(&:strip)).each do |testimonial|
      testimonial.approve!(current_user)
      @approved_size += 1
    end
    flash_success :now, "#{@approved_size} testimonial(s) successfully approved"
    respond_to do |format|
      format.js do
        render :template => "testimonials/destroy_collection.rjs"
      end
    end
  end

  def reject_collection
    @rejected_size = 0
    current_account.testimonials.find(params[:ids].split(",").map(&:strip)).each do |testimonial|
      testimonial.reject!(current_user)
      @rejected_size += 1
    end
    flash_success :now, "#{@rejected_size} testimonial(s) successfully rejected"
    respond_to do |format|
      format.js do
        render :template => "testimonials/destroy_collection.rjs"
      end
    end
  end
  
  def create_contacts
    @created_size = 0
    @failed_size = 0
    current_account.testimonials.find(params[:ids].split(",").map(&:strip)).each do |testimonial|
      if testimonial.create_party!
        @created_size += 1
      else
        @failed_size += 1
      end
    end
    flash_success :now, "#{@created_size} contact(s) successfully created, #{@failed_size} testimonial(s) already have contact attached"
    respond_to do |format|
      format.js 
    end
  end
  
  def embed_code
    count = params[:count] || 1
    conditions = ""
    success = false
    errors = ""
    code = %Q`
{% for testimonial in testimonials %}
  <div class="xlsuite-embed-testimonial">
    <p class="xlsuite-embed-testimonial-body">{{ testimonial.body }}</p>
    <p class="xlsuite-embed-testimonial-author_info">
      {{ testimonial.author.name }},<br />
      {% if testimonial.author.position %}
      {{ testimonial.author.position }}, <br />
      {% endif %}
      {{ testimonial.author.company_name }}
    </p>
  </div>
{% endfor %}
    `
    if !params[:ids].blank? && params[:mode] =~ /select/i
      ids = params[:ids].split(",").map(&:strip)
      ids = Testimonial.find(:all, :select => "id", :conditions => ["id IN (#{ids.join(',')}) AND approved_at IS NOT NULL"]).map(&:id)
      conditions = %Q`{% load_testimonials ids:"#{ids.join(',')}" randomize:#{count} in:testimonials %}`
      if ids.empty?
        errors = "Please select at least one approved testimonial"
      else
        success = true 
      end
    elsif params[:tags] && params[:mode] =~ /tag/i
      tag_list = Tag.parse(params[:tags]).join(",")
      conditions = %Q`{% load_testimonials tagged_any:"#{tag_list}" randomize:#{count} in:testimonials %}`
      success = true
    end
    code_result = conditions + code
    respond_to do |format|
      format.js do
        render :json => {:code => code_result, :success => success, :errors => errors}.to_json
      end
    end
  end

  protected
  
  def load_testimonial
    @testimonial = current_account.testimonials.find(params[:id])
  end

  def load_testimonials
    search_options = {:offset => params[:start], :limit => params[:limit], :order => "created_at DESC"}
    search_options.merge!(:order => "#{params[:sort]} #{params[:dir]}") if params[:sort]
    
    count_options = {}
    if params[:author_id]
      search_options.merge!(:conditions => "testimonials.author_id=#{params[:author_id]}")
      count_options.merge!(:conditions => "testimonials.author_id=#{params[:author_id]}")
    end

    query_params = params[:q]
    unless query_params.blank?
      query_params = query_params.split(/\s+/)
      query_params = query_params.map {|q| q+"*"}.join(" ")
    end

    @testimonials = current_account.testimonials.search(query_params, search_options)
    @testimonials_count = current_account.testimonials.count_results(query_params, count_options)
  end

  def assemble_records(records)
    results = []
    records.each do |record|
      results << truncate_record(record)
    end
    results
  end

  def truncate_record(record)
    {
      :id => record.id,
      :object_id => record.dom_id,
      :author_name => record.author_name,
      :author_company_name => record.author_company_name,
      :email_address => record.email_address,
      :phone_number => record.phone_number,
      :website_url => record.website_url,
      :body => ActionView::Helpers::TextHelper.truncate(ERB::Util.html_escape(record.body)).to_s,
      :status => record.status.to_s,
      :tag_list => record.tag_list.to_s
    }
  end

  def render_json_response
    errors = (@testimonial.errors.full_messages.blank? ? ($! ? $!.message : "")  : render_to_string(:partial => "/shared/error_messages_for", :locals => {:symbol => :testimonial})).to_s
    render :json => {:flash => flash[:notice].to_s, :close => @updated && @close, :errors => errors, 
                     :id => @testimonial.id, :success => @updated || @created }.to_json
  end
  
  def authorized?
    if %w(edit update).index(self.action_name)
      self.load_testimonial
      return true if current_user.can?(:edit_testimonials)
      return @testimonial.writeable_by?(current_user)
    elsif %w(approve_collection reject_collection).index(self.action_name)
      return current_user.can?(:edit_testimonials)
    elsif %w(create_contacts).index(self.action_name)
      return true if current_user.can?(:edit_party)  
    else
      return current_user?
    end
  end    

  class MissingDataException < RuntimeError; end
  class MissingEmailAddressException < MissingDataException
    def message
      "The E-Mail address is required"
    end
  end
end
