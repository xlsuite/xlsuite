module XlSuite
  module SpecHelpers
    def mock_party(new_stubs={})
      stubs = Hash.new
      stubs[:confirmation_token] = nil
      stubs[:staff?] = false
      stubs[:installer?] = false
      stubs[:breadcrumbs] = []
      stubs[:breadcrumbs].stub!(:find_or_initialize_by_url).and_return(mock_breadcrumb())
      stubs[:member_of?] = false
      stubs[:groups] = []

      mock_model(Party, stubs.reverse_merge(new_stubs))
    end

    def mock_breadcrumb(new_stubs={})
      stubs = Hash.new
      stubs[:update_attributes] = true

      mock_model(Breadcrumb, stubs.reverse_merge(new_stubs))
    end

    def mock_account(new_stubs={})
      stubs = Hash.new
      stubs[:expires_at] = 5.hours.from_now
      stubs[:expired?] = false
      stubs[:nearly_expired?] = false

      mock_model(Account, stubs.reverse_merge(new_stubs))
    end

    def mock_domain(new_stubs={})
      mock_model(Domain, new_stubs)
    end

    def mock_future(new_stubs={})
      mock_model(Future, new_stubs)
    end

    def mock_forum_category(new_stubs={})
      stubs = Hash.new
      stubs[:forums] = collection_proxy
      stubs[:topics] = collection_proxy
      stubs[:posts] = collection_proxy

      mock_model(ForumCategory, stubs.reverse_merge(new_stubs))
    end

    def mock_forum(new_stubs={})
      stubs = Hash.new
      stubs[:topics] = collection_proxy
      stubs[:posts] = collection_proxy

      mock_model(Forum, stubs.reverse_merge(new_stubs))
    end

    def mock_topic(new_stubs={})
      stubs = Hash.new
      stubs[:posts] = collection_proxy

      mock_model(ForumTopic, stubs.reverse_merge(new_stubs))
    end

    def mock_post(new_stubs={})
      stubs = Hash.new

      mock_model(ForumPost, stubs.reverse_merge(new_stubs))
    end

    def mock_listing(new_stubs={})
      stubs = Hash.new

      mock_model(Listing, stubs.reverse_merge(new_stubs))
    end

    def mock_address(new_stubs={})
      stubs = Hash.new

      mock_model(AddressContactRoute, stubs.reverse_merge(new_stubs))
    end

    def collection_proxy(*args)
      new_stubs = args.last.kind_of?(Hash) ? args.pop : Hash.new
      returning(args.dup) do |array|
        array.stub!(:count).and_return(array.size)
        new_stubs.each do |selector, value|
          array.stub!(selector).and_return(value)
        end
      end
    end

    alias_method :mock_collection, :collection_proxy
  end
end

describe "All controllers", :shared => true do
  before do
    @account = mock_account
    @domain = mock_domain(:account => @account, :name => "test.host")
    Domain.stub!(:find_or_initialize_by_name).and_return(@domain)
    @controller.stub!(:current_account).and_return(@account)
    @controller.stub!(:current_domain).and_return(@domain)
  end
end

describe "All authenticated controllers", :shared => true do
  it_should_behave_like "All controllers"

  before do
    @user = mock_party(:unread_emails => [])
    @controller.stub!(:current_user?).and_return(true)
    @controller.stub!(:current_user).and_return(@user)
  end
end

module ActionController
  class TestResponse
    def unauthorized?
      self.code.to_s == "401"
    end
  end
end
