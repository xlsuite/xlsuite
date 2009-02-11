require File.dirname(__FILE__) + '/../test_helper'

class ConfigurationTest < Test::Unit::TestCase
  def setup 
    @account = Account.find(1)
  end
  
  def test_int_value
    x = IntegerConfiguration.new(:name => 'x')
    x.set_value! 14

    conf = Configuration.retrieve(:x)
    assert_nil conf.product_id_before_type_cast
    assert_nil conf.float_value_before_type_cast
    assert_nil conf.str_value_before_type_cast
    assert_equal 14, conf.int_value
  end

  def test_float_value
    x = FloatConfiguration.new(:name => 'x')
    x.set_value! 14.31

    conf = Configuration.retrieve(:x)
    assert_nil conf.product_id_before_type_cast
    assert_nil conf.int_value_before_type_cast
    assert_nil conf.str_value_before_type_cast
    assert_equal 14.31, conf.float_value
  end

  def test_string_value
    x = StringConfiguration.new(:name => 'x')
    x.set_value! 'this is a test'

    conf = Configuration.retrieve(:x)
    assert_nil conf.product_id_before_type_cast
    assert_nil conf.int_value_before_type_cast
    assert_nil conf.float_value_before_type_cast
    assert_equal 'this is a test', conf.str_value
  end

  def test_get_and_set_integer
    old_count = Configuration.count
    Configuration.set_default(:carouge, 13)
    assert_equal old_count+1, Configuration.count
    assert_equal 13, Configuration.get(:carouge),
        Configuration.find_by_name(:carouge).inspect
  end

  def test_get_and_set_float
    old_count = Configuration.count
    Configuration.set_default(:carouge, 21.1)
    assert_equal old_count+1, Configuration.count
    assert_equal 21.1, Configuration.get(:carouge),
        Configuration.find_by_name(:carouge).inspect
  end

  def test_get_and_set_string
    old_count = Configuration.count
    Configuration.set_default(:carouge, 'ji')
    assert_equal old_count+1, Configuration.count
    assert_equal 'ji', Configuration.get(:carouge),
        Configuration.find_by_name(:carouge).inspect
  end

  def test_overwrite_on_set
    old_count = Configuration.count

    Configuration.set_default(:colbleu, 14)
    assert_equal old_count+1, Configuration.count

    Configuration.set_default(:colbleu, 15)
    assert_equal old_count+1, Configuration.count

    assert_equal 15, Configuration.get(:colbleu),
        Configuration.find_by_name(:colbleu).inspect
  end

  def test_nil_value
    old_count = Configuration.count
    Configuration.set_default(:nil_test, nil)
    assert_equal old_count+1, Configuration.count

    assert_nil Configuration.retrieve(:nil_test).str_value
    assert_nil Configuration.retrieve(:nil_test).int_value
    assert_nil Configuration.retrieve(:nil_test).float_value
    assert_nil Configuration.retrieve(:nil_test).product_id

    Configuration.set_default(:nil_test, 's')
    Configuration.set_default(:nil_test, nil)

    assert_nil Configuration.retrieve(:nil_test).str_value
    assert_nil Configuration.retrieve(:nil_test).int_value
    assert_nil Configuration.retrieve(:nil_test).float_value
    assert_nil Configuration.retrieve(:nil_test).product_id
  end

  def test_raises_on_unknown_config_option
    assert_raises ConfigurationNotFoundException do
      Configuration.get(:unknown_value)
    end
  end

  def test_boolean_configuration
    Configuration.set_default(:bool_test, false)
    assert !Configuration.get(:bool_test)
    assert_equal BooleanConfiguration, Configuration.retrieve(:bool_test).class

    Configuration.set_default(:bool_test, true)
    assert Configuration.get(:bool_test)
    assert_equal BooleanConfiguration, Configuration.retrieve(:bool_test).class
  end

  def test_full_information_add_boolean
    Configuration.set_full(:admin_only, true, 'acl.admin', 'Do this then do that', @account)
    assert_equal true, Configuration.get(:admin_only, @account)
    assert_equal 'acl.admin', Configuration.retrieve(:admin_only, @account).group_name
    assert_equal 'Do this then do that', Configuration.retrieve(:admin_only, @account).description
  end

  def test_full_information_add_integer
    Configuration.set_full(:admin_only, 246, 'acl.admin', 'Do this then do that', @account)
    assert_equal 246, Configuration.get(:admin_only, @account)
    assert_equal 'acl.admin', Configuration.retrieve(:admin_only, @account).group_name
    assert_equal 'Do this then do that', Configuration.retrieve(:admin_only, @account).description
  end

  def test_full_information_add_float
    Configuration.set_full(:admin_only, 15.1, 'acl.admin', 'Do this then do that', @account)
    assert_equal 15.1, Configuration.get(:admin_only, @account)
    assert_equal 'acl.admin', Configuration.retrieve(:admin_only, @account).group_name
    assert_equal 'Do this then do that', Configuration.retrieve(:admin_only, @account).description
  end

  def test_full_information_add_string
    Configuration.set_full(:admin_only, 'yes', 'acl.admin', 'Do this then do that', @account)
    assert_equal 'yes', Configuration.get(:admin_only, @account)
    assert_equal 'acl.admin', Configuration.retrieve(:admin_only, @account).group_name
    assert_equal 'Do this then do that', Configuration.retrieve(:admin_only, @account).description
  end

  def test_boolean_set_to_zero_equals_false
    bool = BooleanConfiguration.create(:name => 'bool_item')
    assert !bool.new_record?, ":bool not saved: #{bool.errors.full_messages}"
    bool.set_value!(0)
    assert_equal false, bool.value(), 'direct access returns not false'
    assert_not_nil Configuration.find(:first, :conditions => ['name = ?', 'bool_item']),
        ':bool not in DB ?'
    assert_equal false, Configuration.get(:bool_item), 'DB reload returns not false'
  end

  def test_boolean_set_to_one_equals_false
    bool = BooleanConfiguration.create(:name => 'bool_item')
    assert !bool.new_record?, ":bool not saved: #{bool.errors.full_messages}"
    bool.set_value!(1)
    assert_equal true, bool.value(), 'direct access returns not false'
    assert_not_nil Configuration.find(:first, :conditions => ['name = ?', 'bool_item']),
        ':bool not in DB ?'
    assert_equal true, Configuration.get(:bool_item), 'DB reload returns not false'
  end

  def test_boolean_set_to_zero_equals_false_as_string
    bool = BooleanConfiguration.create(:name => 'bool_item')
    assert !bool.new_record?, ":bool not saved: #{bool.errors.full_messages}"
    bool.set_value!('0')
    assert_equal false, bool.value(), 'direct access returns not false'
    assert_not_nil Configuration.find(:first, :conditions => ['name = ?', 'bool_item']),
        ':bool not in DB ?'
    assert_equal false, Configuration.get(:bool_item), 'DB reload returns not false'
  end

  def test_boolean_set_to_one_equals_false_as_string
    bool = BooleanConfiguration.create(:name => 'bool_item')
    assert !bool.new_record?, ":bool not saved: #{bool.errors.full_messages}"
    bool.set_value!('1')
    assert_equal true, bool.value(), 'direct access returns not false'
    assert_not_nil Configuration.find(:first, :conditions => ['name = ?', 'bool_item']),
        ':bool not in DB ?'
    assert_equal true, Configuration.get(:bool_item), 'DB reload returns not false'
  end
end
