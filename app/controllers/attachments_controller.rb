#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class AttachmentsController < ApplicationController
  required_permissions :none
  skip_before_filter :login_required, :only => %w(show)

  def show
    @recipient = current_account.recipients.find_by_uuid!(params[:recipient_uuid])
    @attachment = @recipient.email.attachments.find_by_uuid!(params[:attachment_uuid])
    @asset = @attachment.asset
    
    disposition = case @asset.content_type
    when %r{\A(text|image|audio|video)/}, /xml\Z/
      "inline"
    else
      "attachment"
    end

    response.headers["Cache-Control"] = "private; max-age=#{5.minutes}"
    if request.env["HTTP_X_SENDFILE_CAPABLE"] == "1" then
      logger.debug {"==> Server is X-Sendfile capable"}
      response.headers["X-Sendfile"] = @asset.full_filename
      send_data("", :filename => @asset.filename,
          :type => @asset.content_type, :disposition => disposition)
    else
      send_data(@asset.send(:current_data), :filename => @asset.filename,
          :type => @asset.content_type, :disposition => disposition)
    end
  end

  def destroy
    @email = current_account.emails.find(params[:email_id])
    if current_user == @email.sender.party || current_user.can?(:edit_emails) then
      @attachment = @email.attachments.find(params[:id])
      @attachment.destroy
      flash_success "Attachment #{@attachment.filename} was removed."
    else
      flash_failure "Could not delete: you are not the mail's sender."
    end

    respond_to do |format|
      format.js
    end
  end
end
