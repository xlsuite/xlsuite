require File.dirname(__FILE__) + '/../test_helper'
require 'emails_controller'

# Re-raise errors caught by the controller.
class EmailsController; def rescue_action(e) raise e end; end

class EmailsControllerTest < Test::Unit::TestCase
  def setup
    @controller = EmailsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @account = Account.find(:first)
  end

  context "An authenticated user" do
    setup do
      @bob = login!(:bob)
    end

    context "PUTting to /admin/emails/__ID__ with an attachment" do
      setup do
        @email = @account.emails.create!(:sender => @bob, :tos => "mary@somedomain.com", :subject => "please read", :body => "this is the body")
        put :update, :id => @email.id, :email => {:subject => "new subject", :body => "the new body", :tos => "mary@somedomain.com, john@somedomain.com", :sender => {:name => "Bob", :address => "address@domain.com"}},
          :attachments => [{:uploaded_data => ""}, {:uploaded_data => fixture_file_upload("pictures/large.jpg")}]
      end

      should_assign_to :email
      should_redirect_to "edit_email_path(@email)"
      should_set_the_flash_to(/email .*updated/i)

      should "add one attachments" do
        assert_equal 1, assigns(:email).attachments.count
      end
    end

    context "PUTting to /admin/emails/__ID__" do
      setup do
        @email = @account.emails.create!(:sender => @bob, :tos => "mary@somedomain.com", :subject => "please read", :body => "this is the body")
        put :update, :id => @email.id, :email => {:subject => "new subject", :body => "the new body", :tos => "mary@somedomain.com, john@somedomain.com", :sender => {:name => "Bob", :address => "address@domain.com"}}
      end

      should_assign_to :email
      should_redirect_to "edit_email_path(@email)"
      should_set_the_flash_to(/email .*updated/i)

      should "add no attachments" do
        assert_equal 0, assigns(:email).attachments.count
      end

      should "not release the mail" do
        assert_nil assigns(:email).released_at
      end
    end

    context "POSTing to /admin/emails, with :commit set to 'Save'" do
      setup do
        post :create, :email => {:subject => "This is my mail", :body => "Please read me"}, :attachments => [{:uploaded_data => ""}], :commit => "Save"
      end

      should "not release the mail" do
        deny assigns(:email).released?
      end
    end

    context "POSTing to /admin/emails, with :commit unset" do
      setup do
        post :create, :email => {:subject => "This is my mail", :body => "Please read me"}, :attachments => [{:uploaded_data => ""}]
      end

      should_assign_to :email
      should_redirect_to "emails_path(:folder => 'inbox')"
      should_set_the_flash_to(/mail sent to \d+ recipients/i)

      should "release the mail" do
        assert assigns(:email).released?, "E-Mail should have been released"
      end

      should "have no attachments" do
        assert_equal 0, assigns(:email).attachments.size
      end
    end

    context "POSTing to /admin/emails with an asset in assets[][id]" do
      setup do
        @asset = @account.assets.create!(:uploaded_data => fixture_file_upload("pictures/large.jpg"), :owner => @bob)
        post :create, :email => {:subject => "This is my mail", :body => "Please read me", :inline_attachments => "1"},
          :assets => [{:id => @asset.id}]
      end

      should_assign_to :email
      should_redirect_to "emails_path(:folder => 'inbox')"
      should_set_the_flash_to(/mail sent to \d+ recipients/i)

      should "attach the selected asset" do
        assert_equal [@asset.id], assigns(:email).attachments.map(&:asset_id), "Expected to find the asset's ID, but found something else"
      end
    end

    context "POSTing to /admin/emails with an attachment in attachements[][uploaded_data]" do
      setup do
        post :create, :email => {:subject => "This is my mail", :body => "Please read me", :inline_attachments => "1"},
          :attachments => [{:uploaded_data => fixture_file_upload("pictures/large.jpg")}]
      end

      should_assign_to :email
      should_redirect_to "emails_path(:folder => 'inbox')"
      should_set_the_flash_to(/mail sent to \d+ recipients/i)

      should "release the mail" do
        assert assigns(:email).released?, "E-Mail should have been released"
      end

      should "add one attachment to the email" do
        assert_equal 1, assigns(:email).attachments.size
      end

      should "require inline attachments" do
        assert assigns(:email).inline_attachments?
      end
    end
  end
end
