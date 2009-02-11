require File.dirname(__FILE__) + '/../test_helper'

class PhoneContactRouteTest < Test::Unit::TestCase
  context "A new PhoneContactRoute" do
    setup do
      @route = PhoneContactRoute.new(:name => "Office", :number => "604-222-3333", :extension => "2412")
    end

    should "format itself as '1 (604) 444-5556' when the number is '+1 (604) 444-5556'" do
      @route.number = '+1 (604) 444-5556'
      assert_equal '+1 (604) 444-5556', @route.formatted_number
    end

    should "report it's area code as 604 when the number is '+1 (604) 444-5556'" do
      @route.number = '+1 (604) 444-5556'
      assert_equal '604', @route.area_code
    end

    should "format itself as '(610) 444-5556' when the number is '610-444-5556'" do
      @route.number = '610-444-5556'
      assert_equal '+1 (610) 444-5556', @route.formatted_number
    end

    should "report it's area code as 610 when the number is '610-444-5556'" do
      @route.number = '610-444-5556'
      assert_equal '610', @route.area_code
    end

    should "format itself as '+1 (514) 444-5556' when the number is '15144445556'" do
      @route.number = '15144445556'
      assert_equal '+1 (514) 444-5556', @route.formatted_number
    end

    should "report it's area code as 514 when the number is '15144445556'" do
      @route.number = '15144445556'
      assert_equal '514', @route.area_code
    end

    should "report it's area code as 450 when the number is '4504445556'" do
      @route.number = '4504445556'
      assert_equal '450', @route.area_code
    end

    should "format itself as '444-5556' when the number is '444-5556'" do
      @route.number = '444-5556'
      assert_equal '444-5556', @route.formatted_number
    end

    should "report no area code when the number is '444-5556'" do
      @route.number = '444-5556'
      assert_nil @route.area_code
    end

    should "format itself as '' when the number is '0121 7339645' (UK)" do
      @route.number = '0121 7339645'
      assert_equal "0121 7339645", @route.formatted_number
    end

    should "format itself as '' when the number is '04 73 85 53 53' (France)" do
      @route.number = '04 73 85 53 53'
      assert_equal "04 73 85 53 53", @route.formatted_number
    end

    should "format itself using the name, formatted number and extension" do
      assert_equal "Office: +1 (604) 222-3333 x2412", @route.to_s
    end

    should "format itself using the name, formatted number and no extension when none" do
      @route.extension = nil
      assert_equal "Office: +1 (604) 222-3333", @route.to_s
    end

    should "format itself using the name and extension when no number is available" do
      @route.number = nil
      assert_equal "Office: x2412", @route.to_s
    end

    should "format itself with the number and extension when no name is available" do
      @route.name = nil
      assert_equal "+1 (604) 222-3333 x2412", @route.to_s
    end

    should "format itself using only the extension when no name and number is available" do
      @route.name = @route.number = nil
      assert_equal "x2412", @route.to_s
    end
  end

  context "A saved phone number" do
    setup do
      @account = Account.find(:first)
      @route = @account.phone_contact_routes.create!(:routable => @account.parties.create!, :number => "(604) 111-2223")
    end

    should "be found by similarity when using an exact match" do
      assert_equal @route, @account.phone_contact_routes.find_by_similar_number("(604) 111-2223")
    end

    should "be found when using only the phone number's digits" do
      assert_equal @route, @account.phone_contact_routes.find_by_similar_number("6041112223")
    end

    should "be found when using a similar number (not formatted the same)" do
      assert_equal @route, @account.phone_contact_routes.find_by_similar_number("604-111-2223")
    end
  end
end
