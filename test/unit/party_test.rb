require File.dirname(__FILE__) + '/../test_helper'

class PartyTest < Test::Unit::TestCase
  context "Calling #grant_api_access!" do
    setup do
      @party = accounts(:wpul).parties.create!
    end

    should "generate a new ApiKey" do
      assert_difference ApiKey, :count, 1 do
        @party.grant_api_access!
      end
    end

    should "link the new key to the party" do
      @party.grant_api_access!
      assert_equal @party.api_key, ApiKey.find_by_party_id(@party.id)
    end

    should "link the new key to the party's account" do
      @party.grant_api_access!
      assert_equal accounts(:wpul), ApiKey.find_by_party_id(@party.id).account
    end

    should "return the key" do
      assert_kind_of ApiKey, @party.grant_api_access!
    end

    should "return the existing key if the party already has one" do
      key = @party.grant_api_access!
      assert_equal key, @party.grant_api_access!
    end
  end

  context "Calling #revoke_api_access!" do
    setup do
      @party = accounts(:wpul).parties.create!
    end

    context "on a previously authorized party" do
      setup do
        @key = @party.grant_api_access!
      end

      should "destroy the api key" do
        @party.revoke_api_access!
        assert_raise(ActiveRecord::RecordNotFound) do
          @key.reload
        end
      end
    end

    should "not raise an exception even if the party wasn't authorized" do
      assert_nothing_raised do
        @party.revoke_api_access!
      end
    end
  end

  context "Assigning tag_list to a new party object" do
    setup do
      @party = accounts(:wpul).parties.build(:tag_list => "aloha")
    end
    
    should "not crash when the party is saved" do
      assert @party.save!
    end
    
    should "assign the correct tag after party is saved" do
      @party.save!
      @party.reload
      assert @party.tag_list.index("aloha")
    end
    
    should "remove taggings if tag_list is set to a blank string" do
      @party.tag_list = ""
      @party.save!
      @party.reload
      assert_equal 0, @party.tag_list.size
    end
    
    should "remove taggings if tag_list is set to nil" do
      @party.tag_list = nil
      @party.save!
      @party.reload
      assert_equal 0, @party.tag_list.size
    end    
  end
  
  context "Assigning tag_list to a saved party object" do
    setup do
      @party = parties(:bob) 
    end
    
    should "assign the correct tag after party is saved" do
      @party.tag_list = "aloha, nyam"
      @party.save!
      @party.reload
      assert @party.tag_list.index("aloha")
      assert @party.tag_list.index("nyam")
    end

    should "remove taggings if tag_list is set to a blank string" do
      @party.tag_list = ""
      @party.save!
      @party.reload
      assert_equal 0, @party.tag_list.size
    end
    
    should "remove taggings if tag_list is set to nil" do
      @party.tag_list = nil
      @party.save!
      @party.reload
      assert_equal 0, @party.tag_list.size
    end    
  end

  context "A new party with no contact routes" do
    setup do
      @party = accounts(:wpul).parties.build
    end

    should "build a new Main address when calling #address=" do
      @party.address = {:line1 => "200 Place of Business", :city => "Century Town", :zip => "90210"}

      assert_equal 1, @party.addresses.size
      addr = @party.addresses.first
      assert_match /main/i, addr.name
      assert_equal "200 Place Of Business", addr.line1
      assert_equal "Century Town", addr.city
      assert_equal "90210", addr.zip
    end
  end

  context "A party with no contact routes" do
    setup do
      @party = accounts(:wpul).parties.create!
    end

    should "update the existing Main address when calling #address=" do
      addr = @party.main_address
      addr.line1 = "200 Place of Business"
      addr.save!
      @party.reload

      @party.address = {:line1 => "250 Place of Business", :city => "Century Town", :zip => "90210"}
      @party.save!
      @party.reload

      assert_equal "250 Place Of Business", @party.main_address.line1
    end

    should "create a new Main address when calling #address=" do
      @party.address = {:line1 => "200 Place of Business", :city => "Century Town", :zip => "90210"}
      @party.save!
      @party.reload

      assert_equal 1, @party.addresses.size
      addr = @party.addresses.first
      assert_match /main/i, addr.name
      assert_equal "200 Place Of Business", addr.line1
      assert_equal "Century Town", addr.city
      assert_equal "90210", addr.zip
    end

    should "create a new Office address when calling #address=(:office => {:line1 => ''})" do
      @party.address = {:office => {:line1 => "200 Place of Business", :city => "Century Town", :zip => "90210"}}

      assert_equal 1, @party.addresses.size
      addr = @party.addresses.first
      assert_match /office/i, addr.name
      assert_equal "200 Place Of Business", addr.line1
      assert_equal "Century Town", addr.city
      assert_equal "90210", addr.zip
    end

    should "NOT create a new phone when #phone= is called with {:name => 'main', :number => ''}" do
      @party.phone = {:name => "main", :number => ""}
      assert_equal 0, @party.phones.size
    end
  end

  context "An account owner" do
    setup do
      @owner = accounts(:wpul).owner
    end

    should "not be deletable" do
      assert_equal false, @owner.destroy
      assert_nothing_raised do
        @owner.reload
      end
    end
  end

  context "Parties belonging to a hierarchy of roles (admins => accountants => helpers)" do
    setup do
      @admin_role = accounts(:wpul).roles.find_or_create_by_name(:name => "admins")
      @accountants_role = accounts(:wpul).roles.find_or_create_by_name(:name => "accountants", :parent => @admin_role)
      @helpers_role = accounts(:wpul).roles.find_or_create_by_name(:name => "helpers", :parent => @accountants_role)

      @admin_role.parties << parties(:peter)
      @admin_role.permissions << Permission.find_or_create_by_name("edit_party_security")

      @accountants_role.parties << parties(:mary)
      @accountants_role.permissions << Permission.find_or_create_by_name("edit_invoices")

      @helpers_role.permissions << Permission.find_or_create_by_name("view_invoices")
      @helpers_role.parties << parties(:john)

      [@admin_role, @accountants_role, @helpers_role].each(&:reload)
    end

    should "let John view invoices (helpers CAN view_invoices)" do
      assert_include "view_invoices", parties(:john).total_granted_permissions.map(&:to_s)
    end

    should "NOT let John edit invoices (helpers CANNOT edit_invoices)" do
      assert_not_include "edit_invoices", parties(:john).total_granted_permissions.map(&:to_s)
    end

    should "NOT let John edit party security (helpers CANNOT edit_party_security)" do
      assert_not_include "edit_party_security", parties(:john).total_granted_permissions.map(&:to_s)
    end

    should "let Mary edit invoices (accountants CAN edit_invoices)" do
      assert_include "edit_invoices", parties(:mary).total_granted_permissions.map(&:to_s)
    end

    should "let Mary view invoices (accountants CAN ALSO view_invoices (through the helpers role))" do
      assert_include "view_invoices", parties(:mary).total_granted_permissions.map(&:to_s)
    end

    should "NOT let Mary edit party security (accountants CANNOT edit_party_security)" do
      assert_not_include "edit_party_security", parties(:mary).total_granted_permissions.map(&:to_s)
    end

    should "let Peter view invoices (admins are accountants, which are helpers)" do
      assert_include "view_invoices", parties(:peter).total_granted_permissions.map(&:to_s)
    end

    should "let Peter edit invoices (admins are accountants)" do
      assert_include "edit_invoices", parties(:peter).total_granted_permissions.map(&:to_s)
    end

    should "add edit_own_account to John automatically" do
      assert_include "edit_own_account", parties(:john).total_granted_permissions.map(&:to_s)
    end

    should "add edit_own_contacts_only to John automatically" do
      assert_include "edit_own_contacts_only", parties(:john).total_granted_permissions.map(&:to_s)
    end

    should "only let John view invoices and grant the default permissions" do
      assert_equal %w(edit_own_account edit_own_contacts_only view_invoices).sort,
      parties(:john).total_granted_permissions.map(&:to_s).sort
    end

    should "only let Mary edit and view invoices, and grant the default permissions" do
      assert_equal %w(edit_own_account edit_own_contacts_only edit_invoices view_invoices).sort,
      parties(:mary).total_granted_permissions.map(&:to_s).sort
    end

    should "let Peter edit and view invoices, edit party security and grant the default permissions" do
      assert_equal %w(edit_own_account edit_own_contacts_only edit_invoices view_invoices edit_party_security).sort,
      parties(:peter).total_granted_permissions.map(&:to_s).sort
    end
  end

  context "A party" do
    setup do
      @owner = accounts(:wpul).owner
      @owner.permission_grants.map(&:destroy) #TODO: what did the @owner.roles.delete_all tries to accomplish before?
      @party = accounts(:wpul).parties.create!(:created_by => @owner, :updated_by => @owner)
    end

    should "respond_to?(:generate_effective_permissions)" do
      assert Party.new.respond_to?(:generate_effective_permissions)
    end

    context "having only default permissions with no other permissions" do
      should "be able to read itself" do
        assert @owner.readable_by?(@owner)
      end

      should "be able to write itself" do
        assert @owner.writeable_by?(@owner)
      end

      should "not be able to read another party" do
        deny @party.readable_by?(@owner)
      end

      should "not be able to write another party" do
        deny @party.writeable_by?(@owner)
      end
    end

    context "with :edit_own_account permission" do
      setup do
        @owner.append_permissions(:edit_own_account)
      end

      should "be able to read itself" do
        assert @owner.readable_by?(@owner)
      end

      should "be able to write itself" do
        assert @owner.writeable_by?(@owner)
      end

      should "not be able to read another party" do
        deny @party.readable_by?(@owner)
      end

      should "not be able to write another party" do
        deny @party.writeable_by?(@owner)
      end
    end

    context "with :edit_own_contacts permission" do
      setup do
        @owner.append_permissions(:edit_own_contacts)
      end

      should "be able to read itself" do
        assert @owner.readable_by?(@owner)
      end

      should "be able to write itself" do
        assert @owner.writeable_by?(@owner)
      end

      should "be able to read a party he created" do
        assert @party.readable_by?(@owner)
      end

      should "be able to write a party he created" do
        assert @party.writeable_by?(@owner)
      end

      context "on a foreign party" do
        setup do
          @another_party = accounts(:wpul).parties.create!(:created_by => @party, :updated_by => @party)
        end

        should "not be able to read" do 
          deny @another_party.readable_by?(@owner)
        end

        should "not be able to write" do 
          deny @another_party.writeable_by?(@owner)
        end
      end
    end

    context "with :edit_party permission" do
      setup do
        @owner.append_permissions(:edit_party)
      end

      should "be able to read itself" do
        assert @owner.readable_by?(@owner)
      end

      should "be able to write itself" do
        assert @owner.writeable_by?(@owner)
      end

      should "be able to read a party he created" do
        assert @party.readable_by?(@owner)
      end

      should "be able to write a party he created" do
        assert @party.writeable_by?(@owner)
      end

      context "on a foreign party" do
        setup do
          @another_party = accounts(:wpul).parties.create!(:created_by => @party, :updated_by => @party)
        end

        should "be able to read" do 
          assert @another_party.readable_by?(@owner)
        end

        should "be able to write" do 
          assert @another_party.writeable_by?(@owner)
        end
      end
    end
  end
end

class ArchivedPartyTest < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
    @party = accounts(:wpul).parties.create!(:first_name => "John", :last_name => "Ringo")
  end

  def test_archiving_marks_as_archived
    @party.archive
    assert_not_nil @party.archived_at, 'archived_at not set for archived party'
    assert @party.archived?, 'archived? flag not set'
  end

  def test_destroying_actually_destroys
    @party.destroy
    assert_raises(ActiveRecord::RecordNotFound) { @party.reload }
  end
end

module PartyFinder
  def do_find(options=Hash.new)
    @parties, @total_count = Party.find_by_filters(@filters, options)
    return @parties
  end

  def report_find_failure(message)
    "Expected #{message} to be present, found: #{self.do_find.map {|p| p.display_name}.inspect}"
  end
end

class PartySearchByNameTest < Test::Unit::TestCase
  include PartyFinder

  def setup
    @filters = Hash.new
    @filters[:field] = 'name'
  end

  def test_only_one_party_with_name_mary
    @filters[:name] = 'mary'
    assert_equal 1, self.do_find.size
  end

  def test_mary_is_in_returned_list
    @filters[:name] = 'mary'
    assert self.do_find.include?(parties(:mary))
  end

  def test_at_least_two_parties_with_j_in_name
    @filters[:name] = 'j'
    assert self.do_find.size >= 2
  end
end

class PartySearchByEmailTest < Test::Unit::TestCase
  include PartyFinder

  def setup
    @filters = Hash.new
    @filters[:field] = 'e-mail'
  end

  def test_three_parties_with_goodjob_domain
    @filters[:name] = '@goodjob'
    assert_equal 1, self.do_find.size, report_find_failure('Mary')
  end

  def test_mary_is_the_party_with_midfix_goodjob_in_email
    @filters[:name] = '@goodjob'
    assert self.do_find.include?(parties(:mary)), report_find_failure('Mary')
  end
end

class PartySearchIgnoresDestroyedTest < Test::Unit::TestCase
  include PartyFinder

  def setup
    @filters = Hash.new
    @filters[:field] = 'name'
  end

  def test_no_parties_by_name_when_destroyed
    @filters[:name] = 'sam'
    assert self.do_find.empty?, report_find_failure('no parties')
  end

  def test_destroyed_parties_not_in_customers
    @filters[:field] = 'Tagged ALL'
    @filters[:name] = 'customer'
    assert !self.do_find.map(&:id).include?(57), report_find_failure('not to find Sam')
  end
end

class PartySearchByAddressTest < Test::Unit::TestCase
  include PartyFinder

  def setup
    @filters = Hash.new
    @filters[:field] = 'address'
    @filters[:name] = 'QC'

    @parties = self.do_find
  end

  def test_only_one_party_in_quebec
    assert_equal 1, @parties.size, report_find_failure('only one party in Arkansas')
  end

  def test_bob_is_in_arkansas_one_party_in_arkansas
    assert @parties.include?(parties(:bob)), report_find_failure('Bob')
  end
end

class PartySearchByPhoneTest < Test::Unit::TestCase
  include PartyFinder

  def setup
    @filters = Hash.new
    @filters[:field] = 'phone'
    @filters[:name] = '609'

    @parties = self.do_find
  end

  def test_mary_is_the_only_party_in_the_609_area_code
    assert_equal [parties(:mary)], @parties, report_find_failure('only one party in 609 area code')
  end
end

class PartySearchPaginationTest < Test::Unit::TestCase
  include PartyFinder

  def setup
    @filters = Hash.new
    @filters[:field] = 'name'
    @filters[:name] = ''
  end

  def test_per_page_returns_appropriate_number_of_people
    @parties = self.do_find(:per_page => 2)
    assert_equal 2, @parties.size, "Expected to return two parties, as :per_page is 2.  #{@parties.size} results were returned."
  end

  def test_page_two_returns_second_page_of_results
    @parties = self.do_find(:per_page => 2, :page => 2)
    assert_equal 2, @parties.size, "Expected to return two parties, as :per_page is 2.  #{@parties.size} results were returned."
  end

  def test_page_one_and_page_two_are_different
    @page1 = self.do_find(:per_page => 2, :page => 1)
    @page2 = self.do_find(:per_page => 2, :page => 2)
    assert_equal @page1, @page1 - @page2
  end
end

class PartySearchByAnyTagsTest < Test::Unit::TestCase
  include PartyFinder

  def setup
    @filters = Hash.new
    @filters[:field] = 'Tagged ANY'

    assert !parties(:mary).tag_list.empty?, 'Mary has tags'
    assert !parties(:john).tag_list.empty?, 'John has tags'
    assert !parties(:peter).tag_list.empty?, 'Peter has tags'
  end

  def test_mary_is_one_of_the_parties_with_fast_payer_tag
    @filters[:name] = 'fast-payer'
    assert self.do_find.include?(parties(:mary)), report_find_failure('Mary')
  end

  def test_no_parties_with_tonus_tag
    @filters[:name] = 'tonus'
    assert self.do_find.empty?
  end

  def test_find_parties_with_two_tags_in_search
    @filters[:name] = 'fast-payer mall'
    assert self.do_find.include?(parties(:peter)), report_find_failure('Peter')
    assert self.do_find.include?(parties(:john)), report_find_failure('John')
    assert self.do_find.include?(parties(:mary)), report_find_failure('Mary')
  end
end

class PartySearchByAllTagsTest < Test::Unit::TestCase
  include PartyFinder

  def setup
    @filters = Hash.new
    @filters[:field] = 'Tagged ALL'

    assert !parties(:mary).tag_list.blank?, 'Mary has tags'
    assert !parties(:john).tag_list.blank?, 'John has tags'
    assert !parties(:peter).tag_list.blank?, 'Peter has tags'
  end

  def test_john_is_one_of_the_parties_with_mall_tag
    @filters[:name] = 'mall'
    assert self.do_find.include?(parties(:john)), report_find_failure('John')
  end

  def test_no_parties_with_tonus_tag
    @filters[:name] = 'tonus'
    assert self.do_find.empty?
  end

  def test_finds_the_party_with_both_tags
    @filters[:name] = 'fast-payer mall'
    %w(peter mary john).sort.each do |name|
      logger.info "#{name}\t#{parties(name).tag_list}"
    end
    assert_equal [parties(:peter)].map(&:display_name), self.do_find.map(&:display_name)
  end
end

class TaggedPartyTagWithIdenticalTest < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
    @party = accounts(:wpul).parties.create!
    @party.tag_list = 'customer random'
    @party.reload
  end

  def test_tag_with_customer_again
    assert_nothing_raised {@party.tag 'customer'}
  end
end

class DisplayNameGenerationTest < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
  end

  def test_new_party_generates_display_name_on_save
    party = accounts(:wpul).parties.create!(:first_name => 'johnson', :last_name => 'beausoleil')
    assert_equal 'beausoleil, johnson', party.display_name
  end

  def test_party_display_name_is_email_contact_route_when_none
    party = accounts(:wpul).parties.create!
    party.email_addresses.create!(:email_address => "johnson@beausoleil.net")
    party.reload.save!

    assert_equal "johnson", party.display_name
  end
end

class PartyWithNoMainObjectsTest < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
    @party = accounts(:wpul).parties.create!
  end

  def test_new_main_address
    assert @party.main_address.new_record?, "main address is not a new record"
  end

  def test_new_main_phone
    assert @party.main_phone.new_record?, "main phone is not a new record"
  end

  def test_new_main_link
    assert @party.main_link.new_record?, "main link is not a new record"
  end

  def test_new_main_email
    assert @party.main_email.new_record?, "main email is not a new record"
  end
end

class PartyWithMainObjectsTest < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
    @party = accounts(:wpul).parties.create!
  end

  def test_new_main_address
    @party.addresses.create!(:line1 => "2020")
    assert !@party.reload.main_address.new_record?, "main address is a new record"
    assert_equal "2020", @party.main_address.line1
  end

  def test_new_main_phone
    @party.phones.create!(:number => "123")
    assert !@party.reload.main_phone.new_record?, "main phone is a new record"
    assert_equal "123", @party.main_phone.number
  end

  def test_new_main_link
    @party.links.create!(:url => "www.someplace.net")
    assert !@party.reload.main_link.new_record?, "main link is a new record"
    assert_match /www\.someplace\.net/, @party.main_link.url
  end

  def test_new_main_email
    @party.email_addresses.create!(:address => "bob@someplace.net")
    assert !@party.reload.main_email.new_record?, "main email is a new record"
    assert_equal "bob@someplace.net", @party.main_email.address
  end
end

class PartyCreationReferecesTest < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
    @creator = accounts(:wpul).parties.create!
    @party = accounts(:wpul).parties.create!(:created_by => @creator, :updated_by => @creator)
  end

  def test_recorded_creator
    assert_equal @creator, @party.reload.created_by
    assert_equal @creator.id, @party.created_by_id
  end

  def test_recorded_updator
    assert_equal @creator, @party.reload.updated_by
    assert_equal @creator.id, @party.updated_by_id
  end
end

class PartyReferencesTest < Test::Unit::TestCase
  def setup
    @bob = parties(:bob)
    @mary = parties(:mary)
  end

  def test_add_mary_as_a_referral_of_bob
    @bob.referrals << @mary
    assert_equal @bob, @mary.reload.referred_by
    assert_equal [@mary], @bob.reload.referrals
  end
end

class PartyForumAlias < Test::Unit::TestCase
  def setup
    @bob = parties(:bob)

    @bob.forum_alias = "gollum"
    @bob.save!
  end

  def test_forum_alias_must_be_unique
    @mary = parties(:mary)
    @mary.forum_alias = "gollum"
    deny @mary.save
    assert @mary.errors.full_messages.include?("Forum alias has already been taken"),
        "No error messages for within same account"
  end

  def test_blank_forum_alias_is_ok_too
    @bob.forum_alias = nil
    @bob.save!

    @mary = parties(:mary)
    @mary.forum_alias = ""
    assert_nothing_raised { @mary.save! }
  end

  def test_forum_alias_unique_within_same_account
    @acct = create_account
    assert_nothing_raised { @acct.parties.create!(:forum_alias => "gollum") }
  end
end

class PartyBirthdate < Test::Unit::TestCase
  def setup
    @bob = parties(:bob)
  end

  def test_parses_text_string
    @bob.birthdate = "June 15 1973"
    assert_equal Date.new(1973, 6, 15).to_s(:db), @bob.birthdate.to_s(:db)
  end

  def test_parses_numeric_string
    @bob.birthdate = "1973-6-15"
    assert_equal Date.new(1973, 6, 15).to_s(:db), @bob.birthdate.to_s(:db)
  end
end
