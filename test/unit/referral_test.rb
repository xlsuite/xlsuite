require File.dirname(__FILE__) + '/../test_helper'

class ReferralTest < Test::Unit::TestCase
  setup do
    @account = Account.find(:first)
  end

  context "Creating a referral" do
    setup do
      @referral = @account.referrals.build
    end

    context "with a referrer, reference and subject" do
      setup do
        @referral.reference = listings(:bobs_listing)
        @referral.referral_url = "http://bling.com/vary"
        @referral.referrer = parties(:bob)
        @referral.subject = "Check this out!"
      end

      should "prepare a mail with only the auto-generated body" do
        @referral.save(false)
        assert @referral.email.body.include?(@referral.referral_url),
            "referral URL not found in: #{@referral.email.body.inspect}"
        assert @referral.email.body.include?("Your friend, #{parties(:bob).name.first}"),
            "'Your friend, <name>' not found in: #{@referral.email.body.inspect}"
      end

      should "say 'Your friend said' when there is a body" do
        @referral.body = "Awesome"
        @referral.save(false)
        assert_include "Your friend said", @referral.email.body
      end

      should "say 'Your friend said' when there is no body but default_body is called with force" do
        assert @referral.default_body(true).include?("Your friend said"),
            "'Your friend said' not found in: #{@referral.default_body(true).inspect}"
      end
    end

    should "create a new party for the referrer when the referrer's email address is unknown" do
      assert_difference Party, :count, 1 do
        @referral.from = Friend.new(:name => "Clara", :email => "clara@xlsuite.com")
        @referral.save(false)
      end
      assert_equal @referral.reload.referrer,
          @account.parties.find_by_email_address("clara@xlsuite.com"),
          "Referral's referrer cannot be found by email address"
    end

    should "reuse an existing party when the referrer's email address is already known" do
      assert_difference Party, :count, 0 do
        @referral.from = Friend.new(:name => "Bob", :email => parties(:bob).main_email.address)
        @referral.save(false)
      end
    end

    context "with a known referrer" do
      setup do
        @referral.from = Friend.new(:name => "Bob", :email => parties(:bob).main_email.address)
      end

      should "NOT create a new party when the friend has a blank email address" do
        @referral.friends = [Friend.new(:name => "", :email => "")]
        @referral.save(false)
        assert @referral.email(true).tos.count.zero?,
            "No friends should have been created since the email address is blank"
      end

      should "create a new party for a friend whose email address is unknown" do
        assert_difference Party, :count, 1 do
          @referral.friends = [Friend.new(:name => "Clara", :email => "clara@xlsuite.com")]
          @referral.save(false)
        end

        assert_equal @referral.reload.email.tos.map(&:party),
            [@account.parties.find_by_email_address("clara@xlsuite.com")],
            "Referral's recipients cannot be found by their email addresses"
      end

      should "reuse an existing party for a friend whose email address is known" do
        assert_difference Party, :count, 0 do
          @referral.friends = [Friend.new(:name => "Mary", :email => parties(:mary).main_email.address)]
          @referral.save(false)
        end
      end

      should "fail with a validation error when a friend's email address is not valid" do
        @referral.friends = [Friend.new(:name => "Clara", :email => "tag=customer"),
            Friend.new(:name => "Clara", :email => "carla")]
        deny @referral.save
        full_messages = @referral.errors.full_messages
        assert full_messages.include?("\"tag=customer\" is an invalid address") \
            && full_messages.include?("\"carla\" is an invalid address"),
            "Errors do not reference the bad E-Mail addresses: #{full_messages.inspect}."
      end

      should "fail with a validation error when a sender's email address is not valid" do
        @referral.from = Friend.new(:name => "Clara", :email => "tag")
        deny @referral.save
        assert @referral.errors.full_messages.include?("Invalid sender E-Mail address specified"),
            "Errors do not reference the bad E-Mail address"
      end
    end
  end
end
