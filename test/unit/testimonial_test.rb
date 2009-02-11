require File.dirname(__FILE__) + '/../test_helper'

class TestimonialTest < Test::Unit::TestCase
  setup do
    @account = accounts(:wpul)
  end
  
  context "An existing testimonial" do
    setup do
      @testimonial = @account.testimonials.create!(
        :author_name => "testimonial author",
        :author_company_name => "author company name",
        :body => "Body of the test testimonial",
        :testified_at => Time.now.utc,
        :email_address => "testimonial@xlsuite.com"
      )
    end
    
    context "getting approved" do
      setup do
        @testimonial.approve!(parties(:bob))
      end
      
      should "have its approved_at set" do
        assert_not_nil @testimonial.approved_at
      end
      
      should "have its approved_by set" do
        assert_equal parties(:bob).id, @testimonial.approved_by.id
      end
      
      should "create its author" do
        assert_not_nil @testimonial.author
      end
      
      should "create the profile of its author" do
        assert_not_nil @testimonial.author.profile
      end
    end
  end
  
  context "Creating a party from a testimonial" do
    setup do
      @testimonial = @account.testimonials.create!(
        :author_name => "testimonial author",
        :author_company_name => "author company name",
        :body => "Body of the test testimonial",
        :testified_at => Time.now.utc,
        :email_address => "testimonial@xlsuite.com"
      )
    end
    
    context "that does not have author" do
      context "specifying website_url and phone_number in the testimonial" do
        setup do
          @testimonial.website_url = "xlsuite.com"
          @testimonial.phone_number = "666 777 8888"
          @testimonial.save!
          
          @testimonial.create_party!
          @testimonial.reload
        end
        
        should "relate the testimonial to the newly created party" do
          assert_not_nil @testimonial.author
        end
        
        should "create the main email of the party" do
          assert_equal "testimonial@xlsuite.com", @testimonial.author.main_email.email_address
        end
        
        should "create the main link of the newly created party" do
          assert_equal "xlsuite.com", @testimonial.author.main_link.url
        end
        
        should "create the main phone of the newly created party" do
          assert_equal "666 777 8888", @testimonial.author.main_phone.number
        end
      end
      
      context "that has an avatar" do
        setup do
          @testimonial.avatar = Asset.find(:first)
          @testimonial.save!
          @testimonial.create_party!
          @testimonial.reload
        end
        
        should "copy relate the avatar with the newly created party" do
          assert_equal @testimonial.avatar_id, @testimonial.author.avatar_id
        end
      end
    end
    
  end
end
