require File.dirname(__FILE__) + '/../test_helper'

class ImportTest < Test::Unit::TestCase
  def setup
    file = fixture_file_upload('/files/BIA_contacts_short.csv')
    @import = imports(:bia_contacts)
    @import.file = file
    @import.mappings = {:header_lines_count => 1, 
        :map => [nil, nil, {:model => "Party", :field => "first_name", :name => ""}, nil,
            {:model => "EmailContactRoute", :field => "email_address", :name => "Alternate"}]}
    @import.save!
    @mappings = {
        :header_lines_count=>"0", 
        :map=>[
          nil, 
          nil, 
          nil, 
          {:name=>"", :field=>"first_name", :tr=>"As-is", :model=>"Party"}, 
          {:name=>"", :field=>"last_name", :tr=>"As-is", :model=>"Party"}, 
          {:name=>"", :field=>"company_name", :tr=>"As-is", :model=>"Party"}, 
          {:name=>"", :field=>"position", :tr=>"As-is", :model=>"Party"}, 
          {:name=>"", :field=>"notes", :tr=>"As-is", :model=>"Party"}, 
          {:name=>"Main", :field=>"line1", :tr=>"As-is", :model=>"AddressContactRoute"}, 
          {:name=>"", :field=>"", :tr=>"As-is", :model=>""}, 
          {:name=>"Main", :field=>"city", :tr=>"As-is", :model=>"AddressContactRoute"}, 
          {:name=>"Main", :field=>"state", :tr=>"As-is", :model=>"AddressContactRoute"}, 
          {:name=>"Main", :field=>"zip", :tr=>"As-is", :model=>"AddressContactRoute"}, 
          {:name=>"Main", :field=>"number", :tr=>"As-is", :model=>"PhoneContactRoute"}, 
          {:name=>"", :field=>"", :tr=>"As-is", :model=>""}, 
          {:name=>"Main", :field=>"email_address", :tr=>"As-is", :model=>"EmailContactRoute"}, 
          {:name=>"Office", :field=>"number", :tr=>"As-is", :model=>"PhoneContactRoute"}, 
          {:name=>"Company", :field=>"url", :tr=>"As-is", :model=>"LinkContactRoute"}, 
          nil, 
          nil, 
          nil, 
          {:name=>"", :field=>"", :tr=>"As-is", :model=>""}], 
        :tag_list=>""}
  end
  
  def test_first_x_lines
    rows = @import.first_x_lines(2)
    assert_equal rows.size, 2
    assert rows[1].index("Rania Hatz")
  end
  
  def test_go!
    @import.mappings = @mappings
    @import.account = Account.find(1)
    @import.save!
    assert_difference Party, :count, 2 do
      assert_difference EmailContactRoute, :count, 2 do
        @import.go!
      end
    end
    assert_not_nil party_from_email=EmailContactRoute.find_by_email_address("rania.hatz@gmail.com").routable
    assert_not_nil party=Party.find_by_first_name("Rania")
    assert_equal party.id, party_from_email.id
  end
  
  def test_has_blank_mappings?
    assert !@import.has_blank_mappings?
    @import.mappings[:map] = nil
    assert @import.has_blank_mappings?
    @import.mappings[:map] = [nil, nil, nil, nil, nil, nil, nil]
    assert @import.has_blank_mappings?
  end
  
  def test_reimport_not_duplicate_party
    @import.mappings = @mappings
    @import.account = Account.find(1)
    @import.save!
    assert_difference Party, :count, 2 do
      assert_difference EmailContactRoute, :count, 2 do
        @import.go!
      end
    end
    assert_difference Party, :count, 0 do
      assert_difference EmailContactRoute, :count, 0 do
        @import.go!
      end
    end
  end  
end

class ImportErrorTest < Test::Unit::TestCase

  #self.use_transactional_fixtures = false
  #self.pre_loaded_fixtures = false

  def test_raise_imported_aborted_by_errors
    card_scanner_mappings = {
        :header_lines_count=>"1", 
        :map=>[
          {:name=>"", :field=>"first_name", :tr=>"As-is", :model=>"Party"}, 
          {:name=>"", :field=>"position", :tr=>"As-is", :model=>"Party"}, 
          nil, 
          nil, 
          {:name=>"", :field=>"company_name", :tr=>"As-is", :model=>"Party"},
          {:name=>"Main", :field=>"line1", :tr=>"As-is", :model=>"AddressContactRoute"}, 
          nil, 
          nil, 
          nil, 
          nil, 
          {:name=>"Main", :field=>"number", :tr=>"As-is", :model=>"PhoneContactRoute"}, 
          nil, 
          {:name=>"DID", :field=>"number", :tr=>"As-is", :model=>"PhoneContactRoute"}, 
          nil, 
          {:name=>"Fax", :field=>"number", :tr=>"As-is", :model=>"PhoneContactRoute"}, 
          nil, 
          nil, 
          {:name=>"Main", :field=>"email_address", :tr=>"As-is", :model=>"EmailContactRoute"}, 
          nil, 
          {:name=>"Company", :field=>"url", :tr=>"As-is", :model=>"LinkContactRoute"}, 
          nil, 
          nil, 
          nil, 
          nil, 
          nil], 
        :tag_list=>""}
    new_import = imports(:card_scanner)
    new_import.file = fixture_file_upload('/files/card_scanner.csv')
    new_import.mappings = card_scanner_mappings
    new_import.account = Account.find(1)
    new_import.save!
    assert_difference Party, :count, 0 do
      assert_raise(ImportAbortedByErrors) do
        new_import.go!
      end
    end
  end
end
