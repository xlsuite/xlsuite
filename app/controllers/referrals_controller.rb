#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "ostruct"

class ReferralsController < ApplicationController
  skip_before_filter :login_required
  before_filter :load_email_addresses, :except => %w(show create)
  
  def new
    @referral = current_account.referrals.build(
        :referral_url => dereference_url(params[:referral_url]),
        :return_to => dereference_url(params[:return_to]),
        :reference => dereference_dom_id(params[:reference]),
        :title => params[:title])
    current_user? do
      @referral.from.email = current_user.email_addresses.first.address      
    end
    
    @referral.body = @referral.default_body(true)

    @first_friend = Friend.new
    @other_friends = []
    render_using_public_layout
  end
  
  def contact
    @referral = current_account.referrals.build(
        :referral_url => dereference_url(params[:referral_url]),
        :return_to => dereference_url(params[:return_to]),
        :reference => dereference_dom_id(params[:reference]),
        :title => params[:title])
    current_user? do
      @referral.from.email = current_user.email_addresses.first.address      
    end
    @contact_email = params[:contact]
    render_using_public_layout
  end
  
  def show
    referral = current_account.referrals.find_by_uuid(params[:id])
    session[:referral_id] = referral.id
    redirect_to referral.referral_url
  end

  def create
    referral = params[:referral]
    referral[:from] ||= {}
    referral[:friends] ||= []
    referral[:reference] = dereference_dom_id(referral[:reference])
    %w(return_to referral_url).each do |key|
      referral[key] = dereference_url(referral[key])
    end


    referral[:from] = Friend.new(referral[:from])
    unless referral[:friends].length > 1
      friend_emails = referral[:friends].first[:email].split(',')
      base_referral = referral[:friends].first
      referral[:friends] = []
      friend_emails.each do |email|
        referral[:friends] << base_referral.merge(:email => email)
      end
    end

    referral[:friends].map! {|friend| Friend.new(:name => friend[:name], :email => (friend[:email].scan(EmailContactRoute::ValidAddressRegexp).first rescue nil))}
    referral[:friends].delete_if {|friend| friend.email.blank?}
    
    
=begin
    Referral.transaction do
      current_user? do
        party = Party.find_by_account_and_email_address(current_account, referral[:from].email)
        current_user.email_addresses.create!(:account_id => current_account, :address => referral[:from].email) if party.blank?
      end

      @referral = current_account.referrals.build(referral)
      @referral.save!
      @referral.email.release!
    end
=end

    respond_to do |format|
      format.html do
=begin
        flash_success "Sent the referral to #{@referral.friends.size} friend(s)"
        redirect_to @referral.return_to || @referral.referral_url
=end
        return render(:missing)
      end
      format.js do
        return render(:json => {:success => false}.to_json)
      end
    end
    
    rescue ActiveRecord::RecordInvalid
      respond_to do |format|
        format.html do
          flash_failure $!.message.to_s
          if @referral
            @email = @referral.email 
            @first_friend = @referral.friends.last || Friend.new
            @other_friends = @referral.friends[0 .. -2] || []
            load_email_addresses
          end
          if params[:referral][:contact]
            @contact_email = @referral.friends.first.email if @referral
            render_using_public_layout :action => :contact
          else
            redirect_to_return_to_or_back
          end
        end
        format.js do
          return render(:json => {:success => false, :errors => $!.message}.to_json)
        end
      end
  end

  protected
  # The list of types to which we allow references to be made.  These directly correspond
  # to methods with the same name in Account objects (has_many relationship).
  AllowableReferenceTypes = %w(listing forum_category forum forum_topic forum_post
      product_category product invoice estimate party).freeze

  # Dereference a DOM ID into a real model:
  #  "listing_2341" #=> current_account.listings.find(2341)
  #  nil            #=> nil
  #  ""             #=> nil
  #  "patchinko_12" #=> nil (not in AllowableReferenceTypes)
  def dereference_dom_id(dom_id)
    return nil if dom_id.blank?
    reference_id = dom_id.split("_").last
    reference_type = dom_id.sub("_#{reference_id}", "")
    return nil unless AllowableReferenceTypes.include?(reference_type)

    current_account.send(reference_type.pluralize).find(reference_id)
  end

  # Returns an absolute URL to this website, using current_domain.
  # If the URL refers to another website, we simply return nil,
  # which the Referral validation will catch.
  def dereference_url(url)
    if url =~ %r{\A(https?://#{current_domain.name})?(?::\d{1,5})?/}i then
      if $1 then
        url
      else
        "http://#{host}#{url}"
      end
    else
      nil
    end
  end

  # Return the host of this request.  This is either the one from 
  # the Host HTTP param, or the request's #host.
  def host
    request.env["HTTP_HOST"] || request.host
  end

  def load_email_addresses
    @email_addresses = current_user? ? current_user.email_addresses.map(&:address) : nil
  end
end
