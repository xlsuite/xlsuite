require File.dirname(__FILE__) + '/../test_helper'

class BookTest < Test::Unit::TestCase
  def setup
    @book = books(:test_one)
  end
  
  def test_duplicate
    new_book = @book.duplicate
    new_book_attrs_without_id = new_book.attributes.reject{|key, value| key=="id"}
    old_book_attrs_without_id = @book.attributes.reject{|key, value| key=="id"}
    assert_equal old_book_attrs_without_id, new_book_attrs_without_id
    
    new_book.save!
    assert_equal @book.relations.count, new_book.relations.count
    
    @book.relations.each do |relation|
      relation_attr = relation.attributes.reject{|key, value| key=="book_id"}.symbolize_keys
      assert new_book.relations.find(:first, :conditions => ["classification = :classification AND party_id = :party_id", relation_attr])
    end
  end
end
