require File.dirname(__FILE__) + '/../test_helper'

class FeedTest < Test::Unit::TestCase
  setup do
    @account = accounts(:wpul)
    @bob = parties(:bob)
  end

  context "A new feed" do
    setup do
      @feed = @account.feeds.build
    end
    
    context "without a creator" do
      should "be invalid" do
        deny @feed.valid?, @feed.errors.full_messages.to_sentence
      end
  
      context "with a URL" do
        setup do
          @feed.url = "http://sam.com/"
        end
  
        should "be invalid" do
          deny @feed.valid?, @feed.errors.full_messages.to_sentence
        end
      end
    end
    
    context "with a creator" do
      setup do
        @feed.created_by = @bob
      end
      
      should "be invalid" do
        deny @feed.valid?, @feed.errors.full_messages.to_sentence
      end
  
      context "with a URL" do
        setup do
          @feed.url = "http://sam.com/"
        end

        should "be valid" do
          assert @feed.valid?, @feed.errors.full_messages.to_sentence
        end
      end
    end
  end

  context "An existing feed" do
    setup do
      @feed = @account.feeds.create!(:url => "http://some.feed.com/", :created_by => @bob)
    end

    should "rescue Errno exception from #open_feed in \#refresh" do
      @feed.stubs(:open_feed).raises(Errno::ECONNRESET)
      assert_nothing_raised do
        @feed.refresh
      end
    end

    should "rescue REXML::ParseException exceptions from #open_feed in \#refresh" do
      @feed.stubs(:open_feed).raises(REXML::ParseException.new(""))
      assert_nothing_raised do
        @feed.refresh
      end
    end

    context "that had previously been put in an error state 2 times" do
      setup do
        @feed.parties << @bob = parties(:bob)
        @feed.update_attributes(
          :last_errored_at => 5.hours.ago.utc,
          :error_message => "Errno::ECONNRESET",
          :error_class => "Errno::ECONNRESET",
          :error_count => 2,
          :refreshed_at => 3.seconds.ago.utc)
      end

      context "and fails again" do
        setup do
          @email_count = @account.emails.count
          @feed.handle_error(Errno::ECONNRESET.new, 3.hours)
        end

        should "record the new failure count" do
          assert_equal 3, @feed.error_count
        end

        should "send the mail to the feed's owners" do
          assert_include @bob, Email.find(:first, :order => "id DESC").tos.map(&:party)
        end

        should "deliver an email to the feed's owners" do
          assert_equal @email_count + 1, @account.emails.count
        end
      end

      context "whose feed is now 200 OK again" do
        setup do
          @feed.stubs(:open_feed).returns(stub = stub_everything("feed", :entries => [],
              :publisher => stub_everything("publisher", :name => "name"),
              :author => stub_everything("author", :name => "name")))
          @feed.refresh
        end

        should "clear the last_errored_at column" do
          assert_nil @feed.last_errored_at
        end

        should "clear the error_message column" do
          assert_nil @feed.error_message
        end

        should "clear the error_class column" do
          assert_nil @feed.error_class
        end

        should "clear the error_count column" do
          assert_equal 0, @feed.error_count
        end
      end
    end

    context "returning an Errno::ECONNREFUSED from \#open_feed" do
      setup do
        @feed.stubs(:open_feed).raises(Errno::ECONNREFUSED)
        @feed.refresh
        @feed = @feed.reload
      end

      should "reschedule the feed to be fetched 24 hours later" do
        assert_equal 24.hours.from_now.utc.to_s, @feed.refreshed_at.to_s
      end

      should "record the time at which the error occured" do
        assert_equal Time.now.utc.to_s, @feed.last_errored_at.to_s
      end

      should "record the error class in error_class" do
        assert_equal Errno::ECONNREFUSED.name, @feed.error_class
      end

      should "record the error backtrace in backtrace" do
        assert_not_nil @feed.backtrace
      end

      should "record the error message in error_message" do
        assert_not_nil @feed.error_message
      end

      should "increase the error_count by 1" do
        assert_equal 1, @feed.error_count
      end
    end
  end
end
