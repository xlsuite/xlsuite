#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Public::TestimonialsController < ApplicationController
  skip_before_filter :login_required
  
  def create
    if params[:testimonial][:email_address]
      begin
        Testimonial.transaction do
          avatar_param = params[:testimonial].delete(:avatar)
          @testimonial = current_account.testimonials.build(params[:testimonial])
          @testimonial.created_by = current_user if current_user?
          @testimonial.testified_at = Time.now.utc
          @testimonial.save!
          unless avatar_param.blank? || avatar_param.size == 0 then
            avatar = @testimonial.build_avatar(:uploaded_data => avatar_param, :account => @testimonial.account)
            avatar.crop_resized("70x108")
            avatar.save!
            @testimonial.avatar = avatar
            @testimonial.save!
          end
        end
        respond_to do |format|
          format.html do
            flash_success params[:success_message] || "Your testimonial has been successfully submitted"
            return redirect_to_next_or_back_or_home
          end
          format.js do
            render :json => {:success => true}
          end
        end
      rescue
        errors = $!.message.to_s
        respond_to do |format|
          format.html do
            flash_failure errors
    
            flash[:liquid] ||= {}
            flash[:liquid][:params] = params
            
            return redirect_to_return_to_or_back_or_home
          end
          format.js do
            render :json => {:success => false, :errors => [errors]}
          end
        end
      end
    else
      errors = params[:email_address_error] || "Email address not supplied"
      respond_to do |format|
        format.html do
          flash_failure errors
          return redirect_to_return_to_or_back_or_home
        end
        format.js do
          render :json => {:success => false, :errors => [errors]}
        end
      end
    end
  end  
end
