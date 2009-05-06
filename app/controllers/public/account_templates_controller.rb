#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Public::AccountTemplatesController < ApplicationController
  skip_before_filter :login_required
  
  def index
    conditions = ["stable_account_id IS NOT NULL AND approved_at IS NOT NULL"]
    if params[:search]
      params_search = params[:search].clone
      master_acct = Account.find_by_master(true)
      account_template_ids = []
      industry_account_template_ids = []
      main_theme_account_template_ids = []
      
      if params_search[:main_theme] =~ /^all$/i && params_search[:industry] =~ /^all$/i
        account_template_ids = nil
      else
        if params_search[:industry] && params_search[:industry] !~ /^all$/i
          industry_category = master_acct.categories.find_by_label(params_search[:industry])
          industry_account_template_ids = Categorizable.all(:conditions => {:subject_type => "AccountTemplate", :category_id => industry_category.id}).map(&:subject_id)
        end
        if params_search[:main_theme] && params_search[:main_theme] !~ /^all$/i
          main_theme_category = master_acct.categories.find_by_label(params_search[:main_theme])
          main_theme_account_template_ids = Categorizable.all(:conditions => {:subject_type => "AccountTemplate", :category_id => main_theme_category.id}).map(&:subject_id)
        end
        if main_theme_account_template_ids.empty? || industry_account_template_ids.empty?
          account_template_ids = main_theme_account_template_ids + industry_account_template_ids
        else
          account_template_ids = main_theme_account_template_ids & industry_account_template_ids
        end
        account_template_ids = [0] if account_template_ids.empty?
        
        conditions << "account_templates.id IN (#{account_template_ids.join(',')})"
      end
      
      feature_conditions = params_search.select{|k,v| k =~ /^f_/i && v == "1"}
      feature_conditions.each do |e|
        conditions << (e[0] + " = 1")
      end
    end
      
    
    @account_templates = AccountTemplate.all(:conditions => conditions.join(" AND "))
    respond_to do |format|
      format.js do
        return_text = render_to_string(:template => "account_templates/public_index.html.erb", :layout => false)
        render :text => return_text
      end
    end
  end
end
