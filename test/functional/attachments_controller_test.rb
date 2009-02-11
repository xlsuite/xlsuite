require File.dirname(__FILE__) + '/../test_helper'
require 'attachments_controller'

# Re-raise errors caught by the controller.
class AttachmentsController; def rescue_action(e) raise e end; end

class AttachmentsControllerTest < Test::Unit::TestCase
  def setup
    @controller = AttachmentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @account = Account.find(:first)
  end

  context "An authenticated user with :edit_emails permission" do
    setup do
      @bob = parties(:bob)
      @mary = login_with_permissions!(:mary, :edit_emails)
      @email = @account.emails.create!(:sender => @bob, :tos => @bob, :subject => "reminder", :body => "do the laundry")
      @asset = @account.assets.create!(:owner => @bob, :uploaded_data => fixture_file_upload("pictures/large.jpg", "image/jpg"))
      @attachment = Attachment.create!(:email => @email, :asset => @asset)
    end

    context "on DELETE to #destroy" do
      setup do
        delete :destroy, :email_id => @email.id, :id => @attachment.id
      end

      should "render destroy.rjs" do
        assert_template "destroy.rjs"
      end

      should "destroy the record" do
        assert_raise ActiveRecord::RecordNotFound do
          Attachment.find(@attachment.id)
        end
      end
    end
  end

  context "An authenticated user reading mail" do
    setup do
      @bob = parties(:bob)
      @mary = login_with_no_permissions!(:mary)
      @email = @account.emails.create!(:sender => @bob, :tos => @bob, :subject => "reminder", :body => "do the laundry")
      @asset = @account.assets.create!(:owner => @bob, :uploaded_data => fixture_file_upload("pictures/large.jpg", "image/jpg"))
      @attachment = Attachment.create!(:email => @email, :asset => @asset)
    end

    context "on DELETE to #destroy" do
      setup do
        delete :destroy, :email_id => @email.id, :id => @attachment.id
      end

      should "NOT delete the mail" do
        assert_nothing_raised do
          Attachment.find(@attachment.id)
        end
      end
    end
  end

  context "An authenticated user who sent a mail" do
    setup do
      @bob = login_with_no_permissions!(:bob)
      @email = @account.emails.create!(:sender => @bob, :tos => @bob, :subject => "reminder", :body => "do the laundry")
      @asset = @account.assets.create!(:owner => @bob, :uploaded_data => fixture_file_upload("pictures/large.jpg", "image/jpg"))
      @attachment = Attachment.create!(:email => @email, :asset => @asset)
    end

    context "on DELETE to #destroy" do
      setup do
        delete :destroy, :email_id => @email.id, :id => @attachment.id
      end

      should "render destroy.rjs" do
        assert_template "destroy.rjs"
      end

      should "destroy the record" do
        assert_raise ActiveRecord::RecordNotFound do
          Attachment.find(@attachment.id)
        end
      end
    end
  end

  context "An anonymous visitor" do
    context "on GET to #show with an email + attachment in the DB" do
      setup do
        @email = @account.emails.create!(:sender => parties(:bob), :tos => parties(:mary), :subject => "read this", :body => "this is it")
        @asset = @account.assets.create!(:uploaded_data => fixture_file_upload("assets/report.pdf", "application/pdf"), :owner => parties(:bob))
        assert_equal "application/pdf", @asset.reload.content_type
        @email.assets << @asset

        @recipient = @email.tos.first
        @attachment = @email.attachments.first
      end

      context "and a valid recipient, but invalid attachment UUID" do
        should "raise an ActiveRecord::RecordNotFound exception" do
          assert_raise ActiveRecord::RecordNotFound do
            get :show, :recipient_uuid => @recipient.uuid, :attachment_uuid => @attachment.uuid.succ
          end
        end
      end

      context "and an invalid recipient, but valid attachment UUID" do
        should "raise an ActiveRecord::RecordNotFound exception" do
          assert_raise ActiveRecord::RecordNotFound do
            get :show, :recipient_uuid => @recipient.uuid.succ, :attachment_uuid => @attachment.uuid.succ
          end
        end
      end

      context "and valid recipient and attachment UUIDs" do
        setup do
          get :show, :recipient_uuid => @recipient.uuid, :attachment_uuid => @attachment.uuid
        end

        should_respond_with :success
        should_assign_to :attachment

        should "set the response's content type to the attachment's content type" do
          assert_equal "application/pdf", response.headers["Content-Type"]
        end

        should "set the response's disposition to 'attachment'" do
          assert_include "attachment", response.headers["Content-Disposition"]
        end

        should "set include the attachment's filename in the response's disposition" do
          assert_include @asset.filename, response.headers["Content-Disposition"]
        end
      end

      context "and the server specifies it is X-SendFile capable" do
        setup do
          request.env["HTTP_X_SENDFILE_CAPABLE"] = "1"
          get :show, :recipient_uuid => @recipient.uuid, :attachment_uuid => @attachment.uuid
        end

        should_respond_with :success
        should_assign_to :attachment

        should "ask the server to X-Sendfile" do
          assert_equal @asset.full_filename, response.headers["X-Sendfile"]
        end
      end
    end
  end
end
