#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Public::AffiliatesController < ApplicationController
  skip_before_filter :login_required
  
  def create
    email_address = ""
    ActiveRecord::Base.transaction do
      @affiliate = current_account.affiliates.build(params[:affiliate])
      if params[:contact] && !params[:contact][:email_address].blank?
        if params[:contact][:group_labels]
          groups = current_account.groups.find(:all, :select => "groups.id", :conditions => {:label => params[:contact].delete(:group_labels).split(",").map(&:strip).reject(&:blank?)})
          params[:contact][:group_ids] = groups.map(&:id).join(",") unless groups.empty?
        end

        email_address = params[:contact].delete(:email_address)
        @party = Party.find_by_account_and_email_address(current_account, email_address)
        
        if @party && @party.confirmed?
          # NOP, they confirm already and they only want to create the affiliate
        elsif @party && !@party.confirmed?
          # NOP, what to do? they are not signing up for the site or anything right?
        else
          group_ids = params[:contact].delete(:group_ids) || ""
          @party = current_account.parties.signup!(:domain => self.current_domain, :email_address => {:email_address => email_address}, 
              :party => params[:contact], :group_ids => group_ids, 
              :confirmation_url => lambda {|party, code| confirm_party_url(:id => party, :code => code, 
                :signed_up => params[:signed_up], :return_to => params[:return_to], 
                :confirm => params[:confirm], :gids => group_ids)})
        end
        @affiliate.party = @party
      end
      @created = @affiliate.save
    end
    respond_to do |format|
      format.html do
        if params[:next] && @party
          return redirect_to(params[:next].gsub(/__id__/i, @party.id.to_s))
        end
        redirect_to "/"
      end
      format.js do
        response = {:success => @created}
        response.merge!(@affiliate.attributes) if @created
        render(:json => response.to_json)
      end
      format.json do
        response = {:success => @created}
        response.merge!(@affiliate.attributes) if @created
        render(:json => response.to_json)
      end
    end
  rescue ActiveRecord::RecordInvalid
    if email_address.blank?
      error = $!.message.to_s
    else
      error = "Please check your email address"
    end
    respond_to do |format|
      format.js do 
        response = {:success => false, :error => error}
        render(:json => response.to_json)
      end
      format.json do 
        response = {:success => false, :error => error}
        render(:json => response.to_json)
      end
    end
  end
end
