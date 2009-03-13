#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ReportsController < ApplicationController
  
  required_permissions %w(show create field_auto_complete) => "current_user?"
  
  def show
    report = current_account.reports.find(params[:id])
    respond_to do |format|
      format.html do
        params[:report_id] = report.id
      end
      format.json do
        @results = report.run({:limit => params[:limit], :offset => params[:start]}, params[:sort], params[:dir])
        render(:text => JsonCollectionBuilder::build_from_objects(@results, report.count_total_results))
      end
    end
  end
  
  def create
    params[:report][:lines] = (params[:report].delete(:lines) || []).to_a.sort_by {|e| e.first.to_i}.map(&:last)
    params[:report][:lines].map do |line|
      line["field"] = line["field"].gsub(" ", "_").downcase
    end

    @report = current_account.reports.build(params[:report])
    @report.owner = current_user
    if @report.save!
      flash_success "Successfully created"
      render :action => 'show.rjs', :content_type => 'text/javascript; charset=UTF-8', :layout => false
    else
      render :text => "There is something horribly wrong when creating a report"
    end
  end
  
  def update
    report = current_account.reports.build(params[:id])
    if report.save!
      flash_success "Successfully saved"
      redirect_to report_path(report)
    else
      render :text => "There is something horribly wrong with editing a report"
    end
  end
  
  def field_auto_complete
    params[:model] = params[:model].underscore
    exists = Dir[File.join(RAILS_ROOT, "app", "models", "*.rb")].any? do |filename|
      File.basename(filename, ".rb") == params[:model]
    end

    raise ArgumentError, "Not a model" unless exists

    auto_complete_fields = params[:model].classify.constantize.report_columns
    auto_complete_fields = auto_complete_fields.select {|column, value| column.human_name =~ /#{Regexp.escape(params[:q])}/i}
    render(:partial => "shared/auto_complete", :object => auto_complete_fields )
  end
end
