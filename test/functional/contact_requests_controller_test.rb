require File.dirname(__FILE__) + '/../test_helper'
require 'contact_requests_controller'

# Re-raise errors caught by the controller.
class ContactRequestsController; def rescue_action(e) raise e end; end

module ContactRequestsTest
  class AnAnonymousUserTest < Test::Unit::TestCase
    def setup
      @controller = ContactRequestsController.new
      @request    = ActionController::TestRequest.new
      @request.stubs(:referer).returns("")
      @response   = ActionController::TestResponse.new

      @account = Account.find(:first)
      @contact_request = @account.contact_requests.create!(:name => "Sam Gamgee", :subject => "Help!")
    end

    def test_can_new
      get :new
      assert_response :success
      assert_template "contact_requests/new"
    end

    def test_can_create_and_return_to_specified_url
      assert_difference ContactRequest, :count, 1 do
        post :create, :party => {:first_name => ""},
            :phone => {"main" => {:number => "777 777 7777"}},
            :contact_request => {:name => "John K Meister", :subject => "Help"}, :return_to => "/"
      end

      assert_response :redirect
      assert_redirected_to "/"
    end

    def test_can_create_with_existing_email_address_and_same_party_reused
      @bob = parties(:bob)
      assert_difference ContactRequest, :count, 1 do
        assert_difference Party, :count, 0 do
          assert_difference EmailContactRoute, :count, 0 do
            post :create, :party => {:first_name => "Bob"},
                :email_address => {"Main" => {:email_address => @bob.main_email.address}},
                :contact_request => {:subject => "Help Now!"},
                :return_to => "/we-listen"
          end
        end
      end

      assert_response :redirect
      assert_redirected_to "/we-listen"
      assert_match /Help Now!/, @bob.reload.contact_requests.map(&:subject).inspect
    end

    def test_create_and_show_thank_you_when_no_return_to
      request.env["HTTP_REFERER"] = "/bla"
      assert_difference ContactRequest, :count, 1 do
        post :create, :contact_request => {:name => "John K Meister", :subject => "Help"}
      end

      assert_response :success
      assert_select "p", "Thank you for your submission"
    end

    def test_create_and_render_missing_when_no_return_and_referrer
      assert_difference ContactRequest, :count, 1 do
        post :create, :contact_request => {:name => "John K Meister", :subject => "Help"}
      end

      assert_response :success
      assert_select "p", "Thank you for your submission"
    end

    def test_can_create_party_and_request_in_one_go
      assert_difference Party, :count, 1 do
        assert_difference ContactRequest, :count, 1 do
          assert_difference ContactRequestCheckerFuture, :count, 1 do
            post :create, :party => {:first_name => "John", :last_name => "Baird"},
                :email_address => {"newsletter" => {:email_address => "john@news.com"}},
                :address => {"home" => {:zip => "j3k k3j"}},
                :phone => {"home" => {:number => "111-222-3333"}, "cell" => {:number => "222-333-4444"}},
                :contact_request => {:subject => "I want to party", :body => "I need my lights installed"}
            assert_response :success
            assert_select "p", /thank you/i, response.body
            @contact_request = assigns(:contact_request)
            @contact_request.create_party
          end
        end
      end

      @party = @contact_request.reload.party
      assert_equal "John", @party.first_name
      assert_equal "Baird", @party.last_name

      assert_equal [["Home", "J3KK3J"]],
          @party.addresses(true).map {|a| [a.name, a.to_s]},
          "Check defaults in Configuration (J81: default city, QC: default state, Canada: default country)"
      assert_equal [%w(Cell 222-333-4444), %w(Home 111-222-3333)], @party.phones.find(:all, :order => "name").map {|a| [a.name, a.number]}
      assert_equal [%w(Newsletter john@news.com)], @party.email_addresses(true).map {|a| [a.name, a.address]}

      assert_equal "I want to party", @contact_request.subject
      assert_include "I need my lights installed", @contact_request.body
      assert_equal @party.reload, @contact_request.reload.party
    end

    def test_save_extras_to_contact_requests_body_when_present
      post :create, 
          :email_address => {"main" => {:email_address => "test@test.com"}}, 
          :contact_request => {:name => "John", :subject => "Help!", :body => "I need help"},
          :extra => {:building => "5", :section => "7"}
      assert_response :success
      assert_select "p", /thank you/i, response.body

      @contact_request = assigns(:contact_request)
      extras = @contact_request.body.split("<br />").reject(&:blank?).last
      assert_not_nil extras, "Contact request's body did not contain the YAML document separator:\n#{@contact_request.body}"
      assert extras =~ /building: 5\nsection: 7/
    end

    def test_will_be_shown_the_new_page_if_the_request_is_invalid
      post :create, :contact_request => {}
      assert_response :success
      assert_template "contact_requests/new"
    end

    def test_cannot_index
      get :index
      assert_response :redirect
      assert_redirected_to new_session_path
    end

    def test_cannot_show
      get :show, :id => @contact_request.id
      assert_response :redirect
      assert_redirected_to new_session_path
    end

    def test_cannot_destroy
      assert_difference ContactRequest, :count, 0 do
        delete :destroy, :id => @contact_request.id
      end

      assert_response :redirect
      assert_redirected_to new_session_path
    end

    def test_cannot_complete
      put :complete, :id => @contact_request.id
      assert_response :redirect
      assert_redirected_to new_session_path

      assert !@contact_request.reload.completed?
    end
    
    def test_can_submit_a_new_contact_request_with_an_existing_email_address_not_creating_email_nor_party_duplicates
      EmailContactRoute.delete_all
      email = EmailContactRoute.new(:email_address => "hsandjaja@ixld.com")
      email.routable = parties(:bob)
      email.save!
      email_count = EmailContactRoute.count
      assert_equal 1, email_count
      contact_request_count = ContactRequest.count
      post :create,
          :party => {:first_name => "Harman", :last_name => "Sandjaja", :middle_name => "Surya",
              :company_name => "My Company", :honor => "Mr."}, 
              #NOTE :honor is not a typo, checking if inputting wrong keys are going to break the controller
          :email_address => {"main" => {:email_address => "hsandjaja@ixld.com"}},
          :phone => {"main" => {:number => "6047837454"}},
          :contact_request => {:subject => "SellFM Questionaire",
              :body => "this form is neat!"},
          :extra => {:unit_amount => "3", :buildings_amount => "6-11",
              :unit_rental_amount => "3", :unit_sale_amount => "3",
              :company_desc => "strata council"}
      assert_equal contact_request_count+1, ContactRequest.count
      assert_equal 1, EmailContactRoute.count
      parties(:bob).reload
      assert_equal parties(:bob).first_name, "Bob"
      assert_equal parties(:bob).middle_name, "Surya"
      assert_equal parties(:bob).last_name, "Henry"
      assert_equal parties(:bob).company_name, "Bob's Company"
      assert_nil parties(:bob).honorific                 
    end
    
    def test_submit_contact_request_with_new_email_and_blank_phone_number_create_new_party_and_contact_request
      assert_difference ContactRequest, :count, 1 do
        assert_difference Party, :count, 1 do
          assert_difference ContactRequestCheckerFuture, :count, 1 do
            assert_difference EmailContactRoute, :count, 1 do
              assert_difference PhoneContactRoute, :count, 0 do
                post :create,
                    :party => {:first_name => "Harman", :last_name => "Sandjaja", :middle_name => "Surya",
                        :company_name => "My Company", :honorific => "Mr."}, 
                    :email_address => {"main" => {:email_address => "hsandjaja@ixld.com"}},
                    :phone => {"main" => {:number => ""}},
                    :contact_request => {:subject => "SellFM Questionaire",
                        :body => "this form is neat!"},
                    :extra => {:unit_amount => "3", :buildings_amount => "6-11",
                        :unit_rental_amount => "3", :unit_sale_amount => "3",
                        :company_desc => "strata council"}
                contact_request = assigns(:contact_request)
                contact_request.create_party
                party = Party.find_by_last_name("Sandjaja")
                assert_equal party.first_name, "Harman"
                assert_equal party.middle_name, "Surya"
                assert_equal party.last_name, "Sandjaja"
                assert_equal party.company_name, "My Company"
                assert_equal party.honorific, "Mr."                 
              end
            end
          end
        end
      end      
    end
    
    def test_submit_contact_request_with_only_phone_number_create_new_party_and_new_contact_request
      assert_difference ContactRequest, :count, 1 do
        assert_difference Party, :count, 1 do
          assert_difference ContactRequestCheckerFuture, :count, 1 do
            post :create,
                :party => {:first_name => "Harman", :last_name => "Sandjaja", :middle_name => "Surya",
                    :company_name => "My Company", :honorific => "Mr."}, 
                :email_address => {"main" => {:email_address => ""}},
                :phone => {"main" => {:number => "6047837454"}},
                :contact_request => {:subject => "SellFM Questionaire",
                    :body => "this form is neat!"},
                :extra => {:unit_amount => "3", :buildings_amount => "6-11",
                    :unit_rental_amount => "3", :unit_sale_amount => "3",
                    :company_desc => "strata council"}
            contact_request = assigns(:contact_request)
            contact_request.create_party
          end
        end
      end
    end
    
    def test_submit_contact_request_with_contact_routes_that_have_blank_main_attributes 
      assert_difference ContactRequest, :count, 1 do
        assert_difference Party, :count, 0 do
          assert_difference ContactRequestCheckerFuture, :count, 1 do
            post :create,
                :party => {:first_name => "Harman", :last_name => "Sandjaja", :middle_name => "Surya",
                    :company_name => "My Company", :honorific => "Mr."}, 
                :email_address => {"main" => {:email_address => ""}},
                :phone => {"main" => {:number => ""}},
                :address => {"main" => {:line1 => "", :line2 => "", :line3 => "", :zip => ""}},
                :link => {"main" => {:url => ""}},
                :contact_request => {:subject => "SellFM Questionaire",
                    :body => "this form is neat!"},
                :extra => {:unit_amount => "3", :buildings_amount => "6-11",
                    :unit_rental_amount => "3", :unit_sale_amount => "3",
                    :company_desc => "strata council"}
            contact_request = assigns(:contact_request)
            contact_request.create_party
          end
        end
      end
    end

    def test_submit_contact_request_with_address_contact_route_that_only_contain_state 
      assert_difference ContactRequest, :count, 1 do
        assert_difference Party, :count, 1 do
          post :create,
              :party => {:first_name => "", :last_name => "", :middle_name => "",
                  :company_name => "", :honorific => ""}, 
              :address => {"main" => {:state => "BC"}},
              :contact_request => {:subject => "SellFM Questionaire",
                  :body => "this form is neat!"},
              :extra => {:unit_amount => "3", :buildings_amount => "6-11",
                  :unit_rental_amount => "3", :unit_sale_amount => "3",
                  :company_desc => "strata council"}
          contact_request = assigns(:contact_request)
          contact_request.create_party
        end
      end
    end

  end

  class AnAuthenticatedUserWithNoPermissionsTest < Test::Unit::TestCase
    def setup
      @controller = ContactRequestsController.new
      @request    = ActionController::TestRequest.new
      @request.stubs(:referer).returns("")
      @response   = ActionController::TestResponse.new

      @bob = login_with_no_permissions!(:bob)
    end

    def test_can_submit_a_new_contact_request_with_a_new_email_address
      assert_difference Party, :count, 0 do
        assert_difference EmailContactRoute, :count, 1 do
          assert_difference ContactRequest, :count, 1 do
            post :create, :party => {:first_name => "Bob"},
                :email_address => {"Alternate" => {:email_address => "bobby@longtest.com"}},
                :contact_request => {:subject => "X412"},
                :return_to => "/warning"
          end
        end
      end

      assert_response :redirect
      assert_redirected_to "/warning"
      assert_match /X412/, @bob.contact_requests(true).map(&:subject).inspect
    end

    def test_can_submit_a_new_contact_request_with_no_email_address_and_request_attached_to_authenticated_user
      assert_difference Party, :count, 0 do
        assert_difference EmailContactRoute, :count, 0 do
          assert_difference ContactRequest, :count, 1 do
            post :create, :contact_request => {:subject => "X412"},
                :return_to => "/warning"
          end
        end
      end

      assert_response :redirect
      assert_redirected_to "/warning"
      assert_match /X412/, @bob.contact_requests(true).map(&:subject).inspect
    end
    
    def test_submit_a_new_contact_request_with_new_main_email_address_does_not_overwrite_existing_mail_email_address
      assert_difference Party, :count, 0 do
        assert_difference EmailContactRoute, :count, 0 do
          assert_difference ContactRequest, :count, 1 do
            post :create, :party => {:first_name => "Bob"},
                :email_address => {"Main" => {:email_address => "bobby@longtest.com"}},
                :contact_request => {:subject => "X412"},
                :return_to => "/warning"
          end
        end
      end

      assert_response :redirect
      assert_redirected_to "/warning"
      assert_match /bob@test\.com/, @bob.main_email(true).address
    end
    
    def test_submit_contact_request_with_tag_list
      assert_difference Party, :count, 0 do
        assert_difference Tag, :count, 3 do
          post :create, :party => {:first_name => "Bob", :tag_list => "nya ha"},
            :contact_request => {:subject => "Nya ha"},
            :return_to => "/warning"
          post :create, :party => {:first_name => "Bob", :tag_list => "boo nya ha"},
            :contact_request => {:subject => "Boo nya ha"},
            :return_to => "/warning"
          bob_tag_list = @bob.reload.tags.map(&:name)
          for e in %w(boo nya ha)
            assert bob_tag_list.index(e)
          end
        end
      end
    end
  end

  class AnAuthenticatedUserWithEditContactRequestsPermissionsTest < Test::Unit::TestCase
    def setup
      @controller = ContactRequestsController.new
      @request    = ActionController::TestRequest.new
      @request.stubs(:referer).returns("")
      @response   = ActionController::TestResponse.new

      @bob = Party.new {|r| r.id = 911; r.first_name = "Bob"}
      @bob.stubs(:can?).returns(true)
      @controller.stubs(:current_user?).returns(true)
      @controller.stubs(:current_user).returns(@bob)

      @contact_request = ContactRequest.new {|r| r.id = 932; r.name = "Sam Gamgee"; r.subject = "Help!"; r.created_at = 5.minutes.ago; r.updated_at = 5.minutes.ago; r.account = @account}
      @proxy = Object.new
    end

    def test_can_view_details
      ContactRequest.expects(:find).with {|*args| args.first == @contact_request.id.to_s}.returns(@contact_request)

      get :show, :id => @contact_request.id

      assert_response :success
      assert_template "contact_requests/show"
      assert_equal @contact_request, assigns(:contact_request)
    end

    def test_can_complete_incomplete_request
      ContactRequest.expects(:find).with {|*args| args.first == @contact_request.id.to_s}.returns(@contact_request)
      @contact_request.expects(:complete!).returns(true)

      put :complete, :id => @contact_request.id
      assert_response :redirect
      assert_redirected_to "/admin/contact_requests/#{@contact_request.id}"
    end

    def test_can_destroy_request
      ContactRequest.expects(:find).with {|*args| args.first == @contact_request.id.to_s}.returns(@contact_request)
      @contact_request.expects(:destroy).returns(true)

      delete :destroy, :id => @contact_request.id

      assert_response :redirect
      assert_redirected_to "/admin/contact_requests/"
    end
  end
end
