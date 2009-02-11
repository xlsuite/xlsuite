require File.dirname(__FILE__) + '/../test_helper'

class AdvancedSearchTest < Test::Unit::TestCase
  def setup
    Party.delete_all

    @account0 = create_account
    @account1 = create_account
    @account2 = create_account

    @john = @account0.parties.create!(:first_name => "John", :last_name => "Smith")
    @sam = @account1.parties.create!(:first_name => "Sam", :last_name => "Smith")
  end

  context "Advance search in John's account" do
    should "not find Sam" do
      assert_equal [[], []], AdvancedSearch.perform_search([{:subject_name => "first_name", :subject_value => "sam"}], [], :account => @account0)
    end
    
    should "find John" do
      assert_equal @john, AdvancedSearch.perform_search(
        [{:subject_name => "last_name", :subject_value => "smith"}], [],
        :account => @account0).last.last.last
    end
  end
  
  context "Advanced Search in Sam's account" do
    should "not find John" do
      assert_equal [[], []], AdvancedSearch.perform_search([{:subject_name => "first_name", :subject_value => "john"}], [], :account => @account1)
    end
    
    should "find Sam" do
      assert_equal @sam, AdvancedSearch.perform_search(
        [{:subject_name => "last_name", :subject_value => "smith"}], [],
        :account => @account1).last.last.last
    end
  end
  
  context"Advanced Search in another account" do
    should "not find any smiths" do
      assert_equal [[], []], AdvancedSearch.perform_search(
        [{:subject_name => "last_name", :subject_value => "smith"}], [],
        :account => @account2)
    end
  end
end
