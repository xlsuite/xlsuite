require "#{File.dirname(__FILE__)}/../test_helper"

class PartiesCrudTest < ActionController::IntegrationTest
  include XlSuiteIntegrationHelpers

  def setup
    @bob = parties(:bob)
    @bob.append_permissions(:edit_party)
    host! @bob.account.domains.first.name
    login
  end

  def test_create_new_party
    get new_party_path
    assert_response :success
    assert_template "parties/new"

    assert_select "form[action=?][method=post]", parties_path do
      assert_select "input#new_party_company_name_field[name=?]", "party[company_name]"
      assert_select "#generalContactRoutes" do
        assert_select "input[name=?]", /phone\[\d+\]\[number\]/, :count => 2
        assert_select "input[name=?]", /link\[\d+\]\[url\]/, :count => 2
        assert_select "input[name=?]", /email_address\[\d+\]\[email_address\]/, :count => 1
      end
      assert_select "#new_party_addresses_group" do
        assert_select "input[name=?]", /address\[\d+\]\[line1\]/
      end
      assert_select "input[type=submit][value=Save]"
    end

    assert_difference Party, :count, 1 do
      post parties_path,
          :party => {:company_name => "XLsuite", :first_name => "Riel", :position => "CEO"},
          :address => {"1921" => {:name => "Main", :line1 => "Grand Central Ave", :city => "Vancouver", :state => "BC", :country => "CAN", :zip => "N4K 1L0"}},
          :phone => {"1922" => {:name => "Mobile", :number => "604-444-4444"}, "1923" => {:name => "Main", :number => ""}},
          :link => {"1924" => {:url => "xlsuite.com/blog", :name => "Blog"}, "1925" => {:name => "Main", :url => "xlsuite.org"}},
          :email_address => {"1926" => {:name => "Main", :email_address => "riel@xlsuite.com"}},
          :commit => "Save"
    end

    @riel = assigns(:party).reload
    assert_redirected_to general_party_path(@riel)
    assert_equal "XLsuite", @riel.company_name
    assert_equal "Riel", @riel.name.first
    assert_equal "CEO", @riel.position
    assert_equal 1, @riel.addresses.size, "Wrong number of addresses created"
    assert_equal 1, @riel.phones.size, "Wrong number of phones created"
    assert_equal 2, @riel.links.size, "Wrong number of links created"
    assert_equal 1, @riel.email_addresses.size, "Wrong number of E-Mail addresses created"

    assert_not_nil address = @riel.addresses.find_by_line1("Grand Central Ave")
    assert_equal "Vancouver", address.city
    assert_equal "BC".downcase, address.state.downcase
    assert_equal "CAN".downcase, address.country.downcase
    assert_equal "N4K 1L0", address.zip

    assert_not_nil @riel.phones.find_by_name_and_number("Mobile", "604-444-4444")
    assert_not_nil @riel.links.find_by_name_and_url("Blog", "xlsuite.com/blog")
    assert_not_nil @riel.links.find_by_name_and_url("Main", "xlsuite.org")
    assert_not_nil @riel.email_addresses.find_by_name_and_email_address("Main", "riel@xlsuite.com")

    follow_redirect!
    assert_response :success
    assert_template "parties/notes"
  end
end

