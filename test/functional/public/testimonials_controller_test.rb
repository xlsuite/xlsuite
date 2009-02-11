require File.dirname(__FILE__) + '/../../test_helper'
require 'public/testimonials_controller'

# Re-raise errors caught by the controller.
class Public::TestimonialsController; def rescue_action(e) raise e end; end

class Public::TestimonialsControllerTest < Test::Unit::TestCase
  def setup
    @controller = Public::TestimonialsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @account = accounts(:wpul)
  end

  context "A non logged in user trying to create a testimonial" do
    setup do
      @testimonial_count = Testimonial.count
      post :create, :testimonial => {
        :author_name => "XLsuite admin", 
        :author_company_name => "iXLd Media Inc.",
        :email_address => "aloha@xlsuite.com",
        :phone_number => "666 777 8888",
        :website_url => "xlsuite.com",
        :body => "This is the testimonial"}
      @testimonial = assigns(:testimonial)
    end
    
    should "create the testimonial properly" do
      assert_equal @testimonial_count + 1, Testimonial.count
      assert_not_nil @testimonial
      assert_equal "XLsuite admin", @testimonial.author_name
      assert_equal "iXLd Media Inc.", @testimonial.author_company_name
      assert_equal "aloha@xlsuite.com", @testimonial.email_address
      assert_equal "666 777 8888", @testimonial.phone_number
      assert_equal "xlsuite.com", @testimonial.website_url
    end
  end
end
