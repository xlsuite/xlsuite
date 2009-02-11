require File.dirname(__FILE__) + '/../test_helper'

class TagTest < Test::Unit::TestCase
  def test_parse_empty_string_in_quotes
    assert_kind_of Array, Tag.parse('""')
    assert Tag.parse('""').empty?
  end

  def test_parse_empty_string
    assert_kind_of Array, Tag.parse('')
    assert Tag.parse('').empty?
  end

  def test_parse_blank_string
    assert_kind_of Array, Tag.parse(' ')
    assert Tag.parse(' ').empty?
  end

  def test_parse_nil
    assert_kind_of Array, Tag.parse(nil)
    assert Tag.parse(nil).empty?
  end

  def test_parse_removes_duplicates
    assert_equal %w(bill test), Tag.parse('"bill" test bill test')
  end
end

class TagNameValidityTest < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
  end

  def test_empty_name_is_invalid
    deny Tag.new(:name => "", :account => @account).valid?
  end

  def test_single_letter_name_is_valid
    assert Tag.new(:name => "a", :account => @account).valid?
  end

  def test_single_digit_name_is_valid
    assert Tag.new(:name => "1", :account => @account).valid?
  end

  def test_single_underscore_name_is_invalid
    deny Tag.new(:name => "_", :account => @account).valid?
  end

  def test_single_dash_name_is_invalid
    deny Tag.new(:name => "-", :account => @account).valid?
  end

  def test_two_letters_name_is_valid
    assert Tag.new(:name => "ab", :account => @account).valid?
  end

  def test_two_digits_name_is_valid
    assert Tag.new(:name => "13", :account => @account).valid?
  end

  def test_240_characters_name_is_valid
    assert Tag.new(:name => "A"*240, :account => @account).valid?
  end

  def test_241_characters_name_is_valid
    deny Tag.new(:name => "B"*241, :account => @account).valid?
  end

  def test_name_with_colon_is_valid
    assert Tag.new(:name => "A:B", :account => @account).valid?
  end

  def test_name_with_slash_is_valid
    assert Tag.new(:name => "A/B", :account => @account).valid?
  end
end

class PrefixSuffixTagSearchText < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
    @vanc = @account.tags.create!(:name => "vancouver-interest")
    @vict = @account.tags.create!(:name => "victoria-interest")
    @seq3 = @account.tags.create!(:name => "seqm:/marketing/blanket:position:3", :system => true)
    @seq5 = @account.tags.create!(:name => "seqm:/marketing/blanket:position:5", :system => true)
    @need = @account.tags.create!(:name => "needs-processing")

    @account0 = create_new_account
    @vanc0 = @account0.tags.create!(:name => "vancouver-interest")
  end

  def test_find_all_with_suffix
    assert_equal [@vanc, @vict], @account.tags.with_suffix("interest") {Tag.find(:all, :order => "name")}
  end

  def test_find_initial_with_suffix
    assert_equal @vanc, @account.tags.with_suffix("interest") {Tag.find(:first, :order => "name")}
  end

  def test_find_all_with_prefix
    assert_equal [@vanc], @account.tags.with_prefix("van") {Tag.find(:all, :order => "name")}
  end

  def test_find_initial_with_prefix
    assert_equal @vict, @account.tags.with_prefix("victoria") {Tag.find(:first, :order => "name")}
  end

  def test_find_without_system
    deny @account.tags.regular.find(:all).include?(@seq3)
  end

  def test_find_with_system
    assert @account.tags.system.find(:all).include?(@seq3)
  end

  def test_find_including_system
    assert_equal [@seq3, @seq5], @account.tags.with_prefix("seqm") {Tag.system.find(:all, :order => "name")}
  end

  def test_find_with_prefix_without_system
    assert_equal [@need], @account.tags.with_prefix("needs") {Tag.regular.find(:all, :order => "name")}
  end

  def test_find_in_second_account
    assert_equal @vanc0, @account0.tags.find(:first)
  end
end
