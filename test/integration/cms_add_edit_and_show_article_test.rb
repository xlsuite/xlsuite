require "#{File.dirname(__FILE__)}/../test_helper"

class CmsAddEditAndShowArticleTest < ActionController::IntegrationTest
  include XlSuiteIntegrationHelpers

  def setup
    Layout.delete_all
    Page.delete_all
    @account = parties(:bob).account
    host! @account.domains.first.name
  end

  def test_create_page
    login
    assert_redirected_to blank_landing_url

    parties(:bob).append_permissions(:edit_layouts, :edit_pages)

    assert_layouts_list_empty
    layout = create_layout_titled("Base")

    assert_pages_list_empty
    root_page = create_page_titled("Home", :fullslug => "", :layout => "Base")
    products_page = create_page_titled("Products", :fullslug => "product-catalog", :parent => root_page)
    assert_equal "product-catalog", products_page.fullslug
    assert_equal "**", products_page.domain_patterns
    assert_equal "Base", products_page.layout

    lights_page = create_page_titled("Lights", :fullslug => "product-catalog/lights", :parent => products_page)
    assert_equal "product-catalog/lights", lights_page.fullslug
    assert_equal "**", products_page.domain_patterns
    assert_equal "Base", products_page.layout

    logout

    get "/"
    assert_response :success
    assert_equal "application/xhtml+xml; charset=UTF-8", response.headers["type"], response.headers.inspect
    assert_match /base layout/, response.body
    assert_match /body content value/, response.body

    get "/product-catalog"
    assert_response :success
    assert_equal products_page, assigns(:page)

    get "/product-catalog/lights"
    assert_response :success
    assert_equal lights_page, assigns(:page)
  end

  def create_layout_titled(title)
    get layouts_url
    assert_response :success
    assert_template "layouts/index"

    post layouts_url, :layout => {:title => title, :body => "base layout\n{{ page.body }}",
        :content_type => "application/xhtml+xml", :encoding => "UTF-8"}
    assert_redirected_to layouts_url
    returning assigns(:layout) do |layout|
      follow_redirect!

      assert_select("#layouts li[id=?]", layout.dom_id, {:count => 1},
          "Seaching for \#layouts LI\##{layout.dom_id}, but not found in\n#{response.body}") do
        assert_select "a[href$=?]", edit_layout_path(layout), title,
            "Searching for A.href$=#{layout_path(layout).inspect}, #{title.inspect}, but not found in\n#{response.body}"
      end
    end
  end

  def create_page_titled(title, params={})
    parent_page = params.delete(:parent)

    get new_page_path, :parent_id => parent_page ? parent_page.id : nil
    logger.debug {"#{'-'*72}\n#{response.body}#{'-'*72}"}
    assert_select "form[action$=?][method=post]", pages_path do
      if parent_page then
        assert_select "input#page_layout[value=?]", parent_page.layout
        assert_select "input#page_fullslug[value=?]", parent_page.fullslug + "/"
        assert_select "textarea#page_domain_patterns", parent_page.domain_patterns
      end
    end

    if parent_page then
      params[:layout] = parent_page.layout unless params.has_key?(:layout)
      params[:domain_patterns] = parent_page.domain_patterns unless params.has_key?(:domain_patterns)
      params[:fullslug] = parent_page.fullslug + "/" unless params.has_key?(:fullslug)
    end

    post pages_path, :page => {:behavior => "plain_text", :title => title,
        :status => "published"}.merge(params), :behavior_values => {:text => "body content value"}
    logger.debug {"#{'-'*72}\n#{response.body}#{'-'*72}"}
    returning assigns(:page) do |page|
      assert_not_nil page, "No page object instantiated"
      deny page.new_record?, "Record was not saved: #{page.errors.full_messages.join(", ")}"
      assert_redirected_to edit_page_path(page)

      get pages_path
      assert_select("#pages tr[id=?]", page.dom_id, {:count => 1},
          "Seaching for \#pages TR\##{page.dom_id}, but not found in\n#{response.body}") do
        assert_select "a[href$=?]", edit_page_path(page), title,
            "Searching for A.href$=#{page_path(page).inspect}, #{title.inspect}, but not found in\n#{response.body}"
      end
    end
  end

  def assert_layouts_list_empty
    get layouts_url
    assert_response :success
    assert_template "layouts/index"

    assert_select "a[href$=?]", new_layout_path, "Create", response.body
  end

  def assert_pages_list_empty
    get pages_url
    assert_response :success
    assert_template "pages/index"

    assert_select "#pages" do
      assert_select "li[id^=page]", :count => 0
    end

    assert_select "a[href$=?]", new_page_path, "Create", response.body
  end
end
