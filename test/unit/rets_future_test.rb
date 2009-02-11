require File.dirname(__FILE__) + "/../test_helper"

class RetsFutureTest < Test::Unit::TestCase
  class MockRetsFuture < RetsFuture
    def run_rets(rets)
      self.results[:ran] = true
    end

    def client
      self
    end

    def transaction
      yield(self) if block_given?
    end
  end

  def setup
    @account = accounts(:wpul)
    @future = MockRetsFuture.new(:owner => @account.owner, :account => @account)
    @future.save(false) 
  end

  def test_system_rets_futures_are_authorized_to_run
    @future.system = true
    @future.owner = @future.account = nil
    @future.save(false)
    @future.reload
    assert_nothing_raised do
      @future.run
    end
  end

  def test_raises_missing_account_authorization_when_account_does_not_have_rets_authorization
    assert_raises(MissingAccountAuthorization) do
      @future.run
    end
  end

  def test_transaction_allowed_when_account_has_rets_authorization
    @account.options.rets = true
    @account.save(false)
    assert_nothing_raised do
      @future.run
    end
  end
end
