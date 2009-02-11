require File.dirname(__FILE__) + '/../test_helper'

class LinkCategoryTest < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
    @link_category = @account.link_categories.create!(:name=>'General', :description=>'The description of link category two')
    assert_kind_of LinkCategory, @link_category
  end
  
  def test_create
    assert_equal "General", @link_category.name
    assert_equal "The description of link category two", @link_category.description
  end
  
  def test_create_with_blank_name
    count = LinkCategory.count
    category = @account.link_categories.create(:name=>'', :description=>'')
    assert_match /can't be blank/i, [category.errors.on(:name)].flatten.join(', ')    
    assert_equal LinkCategory.count, count
  end
  
  def test_create_with_more_than_fifty_char_name
    count = LinkCategory.count
    category = @account.link_categories.create(:name=>'A'*51, :description=>'')
    assert_match /maximum.*50\schar/i, [category.errors.on(:name)].flatten.join(', ')
    assert_equal LinkCategory.count, count
  end
  
  def test_create_with_more_than_200_char_description
    count = LinkCategory.count
    category = @account.link_categories.create(:name=>'Test', :description=>'A'*201)
    assert_match /maximum.*200\schar/i, [category.errors.on(:description)].flatten.join(', ')
    assert_equal LinkCategory.count, count
  end
  
  def test_update
    @link_category.name = "General - edited"
    @link_category.description = "The description of link category two - edited"
    assert @link_category.save
    @link_category.reload
    assert_equal "General - edited", @link_category.name
    assert_equal "The description of link category two - edited", @link_category.description
  end
  
  def test_update_with_blank_name
    @link_category.name = ""
    assert !@link_category.save, @link_category.errors.full_messages.join("; ")
    assert_match /can't be blank/i, [@link_category.errors.on(:name)].flatten.join(', ')
    @link_category.reload
    assert_equal "General", @link_category.name
  end
  
  def test_update_with_more_than_fifty_char_name
    @link_category.name = "A"*51
    assert !@link_category.save, @link_category.errors.full_messages.join("; ")
    assert_match /maximum.*50\schar/i, [@link_category.errors.on(:name)].flatten.join(', ')
    @link_category.reload
    assert_equal "General", @link_category.name
  end

  def test_update_with_more_than_200_char_description
    @link_category.description = "A"*201
    assert !@link_category.save, @link_category.errors.full_messages.join("; ")
    assert_match /maximum.*200\schar/i, [@link_category.errors.on(:description)].flatten.join(', ')
    @link_category.reload
    assert_equal "The description of link category two", @link_category.description
  end
  
  def test_destroy
    @link = @account.links.create!(:title=>"test", :url =>'http://www.deviantrealms.com', :description=>'test')
    @link_category.links << @link
    @link_category.save
    links = @link_category.links
    @link_category.destroy
    assert_raise(ActiveRecord::RecordNotFound) { LinkCategory.find(@link_category.id) }
    links.reload
    for link in links
      assert Link.find(link.id)
      assert_nil link.link_category_id
    end
  end
  
end
