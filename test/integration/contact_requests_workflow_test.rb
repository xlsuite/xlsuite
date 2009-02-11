require "#{File.dirname(__FILE__)}/../test_helper"

class ContactRequestsWorkflowTest < ActionController::IntegrationTest
  def setup
    @bob = parties(:bob)
    @bob.append_permissions(:edit_party, :edit_contact_requests)
    @account = @bob.account

    @contact = @account.pages.create!(:fullslug => "contact", :title => "Contact",
        :creator => @bob, :published_at => 5.minutes.ago, :status => "published", :layout => "HTML")
    @account.pages.create!(:fullslug => "contact/thanks", :title => "Thanks for your comment",
        :creator => @bob, :published_at => 5.minutes.ago, :status => "published", :layout => "HTML")
  end

  def test_anonymous_user_can_post_request_and_admin_complete_it
    open_session do |s|
      s.host! @account.domains.first.name
      assert_difference ContactRequest, :count, 1 do
        s.post contact_requests_path,
            :party => {:first_name => "John", :last_name => "Beaver"},
            :email_address => {"alternate" => {:address => "johnbeaver@test.com"}},
            :contact_request => {:name => "Shouldn't be used", :subject => "Need help on the site",
                :body => "I can't find the products section.  What's up ?"},
            :return_to => "/contact/thanks"
        @contact_request = s.assigns(:contact_request)
        assert_not_nil @contact_request, "No @contact_request defined in controller"
        assert_equal "John Beaver", @contact_request.name
        assert_not_nil @contact_request.party
      end
      s.assert_redirected_to "/contact/thanks"
      s.follow_redirect!
      s.assert_response :success
    end

    open_session do |s|
      s.host! @account.domains.first.name
      s.extend XlSuiteIntegrationHelpers
      s.login

      s.get contact_requests_path
      s.assert_response :success
      s.assert_template "contact_requests/index"
      s.assert_select "a[href^=?]", contact_request_path(@contact_request), @contact_request.subject,
          "Could not find link to John Beaver's request on contact request #index page"

      s.get contact_request_path(@contact_request)
      s.assert_response :success
      s.assert_template "contact_requests/show"
      s.assert_select "a[href^=?]", party_path(@contact_request.party), @contact_request.party.name.to_s,
          "Could not find link to John Beaver's party on the contact request #show page"

      # This depends on Ticket's #7124 being accepted into core and ported to the stable branch.
      # See http://dev.rubyonrails.org/ticket/7124
      s.xhr :put, complete_contact_request_path(@contact_request)
      assert @contact_request.reload.completed?, "Contact request not completed"
      assert_not_nil @contact_request.completed_at, "Contact request not completed"
      s.assert_response :success
      s.assert_template "contact_requests/complete.rjs"
    end
  end

  def test_anonymous_user_can_submit_questionaire_as_a_contact_request_and_all_values_are_captured
    open_session do |s|
      s.host! @account.domains.first.name
      assert_difference ContactRequest, :count, 1 do
        s.post contact_requests_path,
            :party => {:first_name => "Harman", :last_name => "Sandjaja",
                :company_name => "My Company"},
            :email_address => {"main" => {:address => "hsandjaja@ixld.com"}},
            :phone => {"main" => {:number => "1112223333"}},
            :contact_request => {:subject => "SellFM Questionaire",
                :body => "this form is neat!"},
            :extra => {:unit_amount => "3", :buildings_amount => "6-11",
                :unit_rental_amount => "3", :unit_sale_amount => "3",
                :company_desc => "strata council"},
            :return_to => "/thanks"

        s.assert_response :redirect
        s.assert_redirected_to "/thanks"
      end

      @party, @contact_request = s.assigns(:party), s.assigns(:contact_request)

      assert_equal "Harman Sandjaja", @party.name.to_s
      assert_equal @party.reload, @contact_request.reload.party
      assert_equal "1112223333", @party.main_phone.number
      assert_equal "hsandjaja@ixld.com", @party.main_email.address
      assert_equal "My Company", @party.company_name

      assert_equal({"unit_amount" => "3", "buildings_amount" => "6-11",
          "unit_rental_amount" => "3", "unit_sale_amount" => "3",
          "company_desc" => "strata council"},
          YAML::load(@contact_request.body.split("\n---").last), "Extra values weren't properly YAML serialized")
    end

    open_session do |s|
      s.host! @account.domains.first.name
      s.extend XlSuiteIntegrationHelpers
      s.login

      s.get contact_requests_path
      s.assert_response :success
      s.assert_template "contact_requests/index"
      s.assert_select "a[href^=?]", contact_request_path(@contact_request), @contact_request.subject,
          "Could not find link to Harman Sandjaja's questionaire result on contact request #index page"

      s.get contact_request_path(@contact_request)
      s.assert_response :success
      s.assert_template "contact_requests/show"
      s.assert_select "a[href^=?]", party_path(@contact_request.party), @contact_request.party.name.to_s,
          "Could not find link to Harman Sandjaja's on the contact request #show page"

      # This depends on Ticket's #7124 being accepted into core and ported to the stable branch.
      # See http://dev.rubyonrails.org/ticket/7124
      s.xhr :put, complete_contact_request_path(@contact_request)
      assert @contact_request.reload.completed?, "Contact request not completed"
      assert_not_nil @contact_request.completed_at, "Contact request not completed"
      s.assert_response :success
      s.assert_template "contact_requests/complete.rjs"
    end
  end
end
