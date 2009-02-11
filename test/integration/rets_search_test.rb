require "#{File.dirname(__FILE__)}/../test_helper"

class RetsSearchTest < ActionController::IntegrationTest
  include XlSuiteIntegrationHelpers

  def setup
    host! Domain.find(:first).name
    RetsMetadata.create!(:name => "METADATA-RESOURCE",
        :date => Date.today, :version => "1.2.3",
        :values => [{"ResourceID" => "Property", "Description" => "MLS Properties"}])
    RetsMetadata.create!(:name => "METADATA-CLASS:Property",
        :date => Date.today, :version => "1.2.3",
        :values => [{"Description" => "Cross Property", "ClassName" => "11"}])
    RetsMetadata.create!(:name => "METADATA-TABLE:Property:11",
        :date => Date.today, :version => "1.2.3",
        :values => [{"SystemName" => "8293", "LongName" => "Listing Date"},
                    {"SystemName" => "1029", "LongName" => "Address"},
                    {"SystemName" => "123", "LongName" => "Status", "LookupName" => "882"}])
    RetsMetadata.create!(:name => "METADATA-LOOKUP_TYPE:Property:882",
        :date => Date.today, :version => "1.2.3",
        :values => [{"Value" => "A", "LongValue" => "Active"},
                    {"Value" => "I", "LongValue" => "Inactive"}])

    parties(:bob).append_permissions(:access_rets)
    login
  end

  def test_can_execute_a_search
    get "/admin/rets;search"
    assert_response :success
    assert_template "rets/search"

    assert_select "form[action$=?][method=post]", do_search_rets_path do
      assert_select "select#search_resource[name=?]", "search[resource]" do
        assert_select "option[value=?]", "Property", :text => "MLS Properties"
      end
      assert_select "select#search_class[name=?]", "search[class]" do
        assert_select "option", :count => 0
      end
      assert_select "select#field" do
        assert_select "option", :count => 0
      end
    end

    get "/admin/rets;classes", "resource" => "Property"
    assert_response :success
    assert_select "option[value=?]", "11", :text => "Cross Property"

    get "/admin/rets;fields", "resource" => "Property", "class" => "11"
    assert_response :success
    assert_select "option[value=?][lookup=?]", "123", "882", :text => "Status"

    get "/admin/rets;lookup", "resource" => "Property", "id" => "882"
    assert_response :success
    assert_select "option[value=?]", "A", :text => "Active"
    assert_select "option[value=?]", "I", :text => "Inactive"
    assert_select "option[value=?]", ".ANY.", :text => /any value/i
    assert_select "option[value=?]", ".EMPTY.", :text => /no value/i
  
    post "/admin/rets;do_search", "search" => {"limit" => "1", "resource" => "Property", "class" => "11"},
        "line" => { "1" => {"field" => "Status", "operator" => "eq", "from" => "A", "to" => ""},
                    "2" => {"field" => "Address", "operator" => "start", "from" => "Brandybuck St", "to" => ""},
                    "3" => {"field" => "Listing Date", "operator" => "between", "from" => "(yesterday)", "to" => "(today)"}}
    future = assigns(:future)
    assert_not_nil future, "No future created"
    deny future.new_record?, "future should have been saved"
    assert_redirected_to future_path(future)

    args = {:search => {:limit => "1", :resource => "Property", :class => "11"},
            :lines => [ {:field => "Status", :operator => "eq", :from => "A", :to => ""},
                        {:field => "Address", :operator => "start", :from => "Brandybuck St", :to => ""},
                        {:field => "Listing Date", :operator => "between", :from => "(yesterday)", :to => "(today)"}]}
    assert_equal args, future.args
  end
end
