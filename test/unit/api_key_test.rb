require File.dirname(__FILE__) + '/../test_helper'

class ApiKeyTest < Test::Unit::TestCase
  setup do
    @apikey = ApiKey.create!(:party => parties(:bob), :account => accounts(:wpul))
  end

  should "generate a key on save" do
    assert_not_nil @apikey.key
  end

  should "make the key a valid UUID" do
    assert_equal @apikey.key, UUID.parse(@apikey.key).to_s
  end
end
