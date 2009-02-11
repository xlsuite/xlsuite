require File.dirname(__FILE__) + "/../test_helper"

class PartyEmailValidationTest < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
    @party = @account.parties.create!
    @email = @party.email_addresses.build(:name => "Personal")
  end

  context "An account with no prior E-Mail addresses" do
    setup do
      EmailContactRoute.delete_all
    end

    context "with party whose E-Mail address is 'bob@test.com'" do
      setup do
        @email.email_address = "bob@test.com"
        @email.save!
      end

      should "be prevent another party from using that E-Mail address" do
        new_party = @account.parties.create!
        assert_raises(ActiveRecord::RecordInvalid) do
          EmailContactRoute.create!(:routable => new_party, :email_address => "bob@test.com")
        end
      end

      should "NOT prevent another party in another account from using that E-Mail address" do
        @account2 = Account.new(:title => "account2")
        @account2.expires_at = 15.minutes.from_now
        @account2.save!

        owner2 = @account2.parties.create!(:first_name => "me")
        @email2 = owner2.main_email
        @email2.address = "bob@teksol.info"
        assert_nothing_raised { @email2.save! }
      end
    end

    should "have valid addresses" do
      @email.email_address = "bob@test.com"
      @email.valid?
      assert_nil @email.errors.on(:email_address)

      @email.email_address = "bob@test-host.com"
      @email.valid?
      assert_nil @email.errors.on(:email_address)

      @email.email_address = "bob-party@test.com"
      @email.valid?
      assert_nil @email.errors.on(:email_address)

      @email.email_address = "bob%notes@test.com"
      @email.valid?
      assert_nil @email.errors.on(:email_address)

      @email.email_address = "bob@test.com"
      @email.valid?
      assert_nil @email.errors.on(:email_address)

      @email.email_address = "bob.me@test.com"
      @email.valid?
      assert_nil @email.errors.on(:email_address)

      @email.email_address = "bob@test.ca"
      @email.valid?
      assert_nil @email.errors.on(:email_address)

      @email.email_address = "bob@test.museum"
      @email.valid?
      assert_nil @email.errors.on(:email_address)

      @email.email_address = "bob@multi.domain.test.com"
      @email.valid?
      assert_nil @email.errors.on(:email_address)
    end

    should "have regular invalid addresses" do
      @email.email_address = "bob"
      @email.valid?
      assert_match /is invalid/, @email.errors.on(:email_address).to_s

      @email.email_address = "@test.com"
      @email.valid?
      assert_match /is invalid/, @email.errors.on(:email_address).to_s

      @email.email_address = "bob@test.c"
      @email.valid?
      assert_match /is invalid/, @email.errors.on(:email_address).to_s

      @email.email_address = ""
      @email.valid?
      assert_match /can't be blank/, @email.errors.on(:email_address).to_s #' VIM close quote

      @email.email_address = nil
      @email.valid?
      assert_match /can't be blank/, @email.errors.on(:email_address).to_s #' VIM close quote
    end
  end

  def test_formatted_string
    @email.email_address = "johnny@test.com"
    assert_equal @email.email_address, @email.to_s
    @email.save!

    @party.name = Name.new("last", "first", "middle")
    @party.save!

    assert_equal %Q("first middle last" <johnny@test.com>), @email.reload.to_formatted_s
  end

  def test_empty_is_invalid
    @email.email_address = ""
    assert !@email.valid?
  end

  def test_nil_is_invalid
    @email.email_address = nil
    assert !@email.valid?
  end

  def test_decode_address_only
    name, address = EmailContactRoute.decode_name_and_address("francois@teksol.info")
    assert_blank name
    assert_equal "francois@teksol.info", address
  end

  def test_decode_address_from_angle_brackets
    name, address = EmailContactRoute.decode_name_and_address("francois <francois@teksol.info>")
    assert_equal "francois", name
    assert_equal "francois@teksol.info", address
  end

  def test_decode_name_from_quotes_and_address_from_angle_brackets
    name, address = EmailContactRoute.decode_name_and_address(%q!"francois" <francois@teksol.info>!)
    assert_equal "francois", name
    assert_equal "francois@teksol.info", address
  end

  def test_email_contact_route_to_formatted_s_decoding
    assert parties(:bob).any_emails?, "Bob doesn't have an E-Mail address"
    addr = parties(:bob).main_email
    name, address = EmailContactRoute.decode_name_and_address(addr.to_formatted_s)
    assert_equal name, parties(:bob).name.to_forward_s, "Could not decode #{addr.to_formatted_s.inspect}"
    assert_equal addr.address, address, "Could not decode #{addr.to_formatted_s.inspect}"
  end
end
