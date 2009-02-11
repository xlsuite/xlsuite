require File.dirname(__FILE__) + '/../test_helper'

class DomainTest < Test::Unit::TestCase
  def setup
    @account = create_account
  end

  should "reject 'magrheb' as a domain name" do
    assert_invalid @account.domains.build(:name => "magrheb")
  end

  should "reject 'm' as a domain name" do
    assert_invalid @account.domains.build(:name => "m")
  end

  should "reject '-' as a domain name" do
    assert_invalid @account.domains.build(:name => "-")
  end

  should "reject 'a'*64 as a domain name" do
    assert_invalid @account.domains.build(:name => "a"*64)
  end

  should "accept 'my.domain.name' as a domain name" do
    assert_valid @account.domains.build(:name => "my.domain.name")
  end

  should "accept 'my.museum' as a domain name" do
    assert_valid @account.domains.build(:name => "my.museum")
  end

  should "accept 'my.sub.domain.name' as a domain name" do
    assert_valid @account.domains.build(:name => "my.sub.domain.name")
  end

  should "accept 'my-very-long.domain-name_with_underscores.com' as a domain name" do
    assert_valid @account.domains.build(:name => "my-very-long.domain-name_with_underscores.com")
  end

  should "accept '1234.domain' as a domain name" do 
    assert_valid @account.domains.build(:name => "1234.domain")
  end

  should "reject '1234.5678' as a domain name" do
    assert_invalid @account.domains.build(:name => "1234.5678")
  end

  should "reject '1234' as a domain name" do
    assert_invalid @account.domains.build(:name => "1234")
  end

  should "reject 'mail' as a domain prefix" do
    deny Domain.new(:account => @account, :name => 'mail.xlsuite.net').valid?
  end

  should "reject 'news' as a domain prefix" do
    deny Domain.new(:account => @account, :name => 'news.weputuplights.com').valid?
  end

  should "reject 'ftp' as a domain prefix" do
    deny Domain.new(:account => @account, :name => 'ftp.weputlightsup.com').valid?
  end

  should "reject 'gopher' as a domain prefix" do
    deny Domain.new(:account => @account, :name => 'gopher.xlsuite.com').valid?
  end

  should "reject 'admin' as a domain prefix" do
    deny Domain.new(:account => @account, :name => 'admin.xlsuite.net').valid?
  end

  should "reject 'pop' as a domain prefix" do
    deny Domain.new(:account => @account, :name => 'pop.xlsuite.net').valid?
  end

  should "reject 'smtp' as a domain prefix" do
    deny Domain.new(:account => @account, :name => 'smtp.xlsuite.net').valid?
  end

  should "reject 'imap' as a domain prefix" do
    deny Domain.new(:account => @account, :name => 'imap.xlsuite.net').valid?
  end

  should "require a domain name" do
    deny Domain.new(:account => @account).valid?
  end

  should "accept 'mailSOMETHING' as a prefix" do
    assert Domain.new(:account => @account, :name => "mailtransport.net").valid?
  end

  should "accept valid names" do
    assert Domain.new(:account => @account, :name => 'francois.xlsuite.net').valid?
    assert Domain.new(:account => @account, :name => 'francois.com').valid?
  end

  should "ensure uniqueness of the domain name" do
    Domain.create!(:account => @account, :name => 'francois.xlsuite.net')
    deny Domain.new(:account => @account, :name => 'francois.xlsuite.net').valid?
  end

  context "A domain" do
    setup do
      @domain = Domain.new(:account => @account, :routes => {}, :name => "xlsuite.com")
    end

    context "#recognize" do
      setup do
        @params = {:id => 13, :label => "francois", }
        XlSuite::Routing.stubs(:recognize).returns({:pages => [13], :params => @params})
        @pages = [stub_everything("page", :patterns => ["**"])]
        @page = @pages.first
        @account.pages.stubs(:find).returns(@pages)
      end

      should "return nil when route recognition fails" do
        XlSuite::Routing.stubs(:recognize).returns(nil)
        assert_nil @domain.recognize("/foo")
      end

      should "delegate route recognition to XlSuite::Routing#recognize" do
        XlSuite::Routing.expects(:recognize).with("/foo", @domain.routes).returns(nil)
        @domain.recognize("/foo")
      end

      should "find the pages returned by XlSuite::Routing#recognize" do
        @account.pages.expects(:find).with([13]).returns(@pages)
        @domain.recognize("/foo")
      end

      should "select the best match for the domain" do
        @pages.expects(:best_match_for_domain).with(@domain).returns(@pages.first)
        @domain.recognize("/foo")
      end

      should "return the pages as the first element of the result" do
        assert_equal @pages.first, @domain.recognize("/foo").first
      end

      should "return the parameters as the last element of the result" do
        assert_equal @params, @domain.recognize("/foo").last
      end
    end

    context "#recognize!" do
      should "raise an ActiveRecord::RecordNotFound exception when route recognition fails" do
        XlSuite::Routing.stubs(:recognize).returns(nil)
        assert_raise ActiveRecord::RecordNotFound do
          @domain.recognize!("/foo")
        end
      end
    end

    context "named 'liveinsurrey.com'" do
      setup do
        @domain.name = "liveinsurrey.com"
      end

      should "match 'liveinsurrey.com'" do
        assert @domain.matches?("liveinsurrey.com")
      end

      should "not match 'xlsuite.com'" do
        deny @domain.matches?("xlsuite.com")
      end

      should "not match 'www.liveinsurrey.com'" do
        deny @domain.matches?("www.liveinsurrey.com")
      end

      should "match ''" do
        assert @domain.matches?("")
      end

      should "match '*'" do
        assert @domain.matches?("*")
      end

      should "match '**'" do
        assert @domain.matches?("**")
      end
    end

    context "named 'surrey.livein.com'" do
      setup do
        @domain.name = "surrey.livein.com"
      end

      should "not match '*.com'" do
        deny @domain.matches?("*.com")
      end

      should "match '**.com'" do
        assert @domain.matches?("**.com")
      end
    end
  end
end
