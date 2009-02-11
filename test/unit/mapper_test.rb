require File.dirname(__FILE__) + '/../test_helper'

class DecodeMappingsTest <  Test::Unit::TestCase

  def setup
    @bia_contact_mapping_params = {
      :header_lines_count=>"1", 
      :map=>{
        "1"=>{:name=>"", :field=>"", :tr=>"As-is", :model=>""}, 
        "2"=>{:name=>"", :field=>"", :tr=>"As-is", :model=>""}, 
        "3"=>{:name=>"", :field=>"", :tr=>"As-is", :model=>""}, 
        "4"=>{:name=>"", :field=>"first_name", :tr=>"As-is", :model=>"Party"}, 
        "5"=>{:name=>"", :field=>"last_name", :tr=>"As-is", :model=>"Party"}, 
        "6"=>{:name=>"", :field=>"company_name", :tr=>"As-is", :model=>"Party"}, 
        "7"=>{:name=>"", :field=>"position", :tr=>"As-is", :model=>"Party"}, 
        "8"=>{:name=>"", :field=>"notes", :tr=>"As-is", :model=>"Party"}, 
        "9"=>{:name=>"Main", :field=>"line1", :tr=>"As-is", :model=>"AddressContactRoute"}, 
        "10"=>{:name=>"", :field=>"", :tr=>"As-is", :model=>""}, 
        "11"=>{:name=>"Main", :field=>"city", :tr=>"As-is", :model=>"AddressContactRoute"}, 
        "12"=>{:name=>"Main", :field=>"state", :tr=>"As-is", :model=>"AddressContactRoute"}, 
        "13"=>{:name=>"Main", :field=>"zip", :tr=>"As-is", :model=>"AddressContactRoute"}, 
        "22"=>{:name=>"", :field=>"", :tr=>"As-is", :model=>""}, 
        "14"=>{:name=>"Main", :field=>"number", :tr=>"As-is", :model=>"PhoneContactRoute"}, 
        "15"=>{:name=>"", :field=>"", :tr=>"As-is", :model=>""}, 
        "16"=>{:name=>"Main", :field=>"email_address", :tr=>"As-is", :model=>"EmailContactRoute"}, 
        "17"=>{:name=>"Office", :field=>"number", :tr=>"As-is", :model=>"PhoneContactRoute"}, 
        "18"=>{:name=>"Company", :field=>"url", :tr=>"As-is", :model=>"LinkContactRoute"}, 
        "19"=>{:name=>"", :field=>"", :tr=>"As-is", :model=>""}, 
        "20"=>{:name=>"", :field=>"", :tr=>"As-is", :model=>""}, 
        "21"=>{:name=>"", :field=>"", :tr=>"As-is", :model=>""}}, 
      :tag_list=>"import test"}
  end
  
  def test_should_return_blank_hash
    assert Mapper.decode_mappings(nil).blank?
  end
  
  def test_should_decode_correctly
    decoded_mappings = Mapper.decode_mappings(@bia_contact_mapping_params)
    assert_equal "import test", decoded_mappings[:tag_list]
    assert_equal 1, decoded_mappings[:header_lines_count]
    assert_equal @bia_contact_mapping_params[:map].size, decoded_mappings[:map].size
    expected_map = [nil, nil, nil, 
      {:name=>"", :field=>"first_name", :model=>"Party", :tr=>"As-is"}, 
      {:name=>"", :field =>"last_name", :model=>"Party", :tr=>"As-is"}, 
      {:name=>"", :field=>"company_name", :model=>"Party", :tr=>"As-is"}, 
      {:name=>"", :field=>"position", :model=>"Party", :tr=>"As-is"}, 
      {:name=>"", :field=>"notes", :model=>"Party", :tr=>"As-is"}, 
      {:name=>"Main", :field=>"line1", :model=>"AddressContactRoute", :tr=>"As-is"}, 
      nil, 
      {:name=>"Main", :field=>"city", :model=>"AddressContactRoute", :tr=>"As-is"}, 
      {:name=>"Main", :field=>"state", :model=>"AddressContactRoute", :tr=>"As-is"}, 
      {:name=>"Main", :field=>"zip", :model=>"AddressContactRoute", :tr=>"As-is"}, 
      {:name=>"Main", :field=>"number", :model=>"PhoneContactRoute", :tr=>"As-is"}, 
      nil, 
      {:name=>"Main", :field=>"email_address", :model=>"EmailContactRoute", :tr=>"As-is"}, 
      {:name=>"Office", :field=>"number", :model=>"PhoneContactRoute", :tr=>"As-is"}, 
      {:name=>"Company", :field=>"url", :model=>"LinkContactRoute", :tr=>"As-is"}, 
      nil, nil, nil, nil]
    assert_equal expected_map, decoded_mappings[:map]
  end
end

class MapperTest < Test::Unit::TestCase
  def setup
    bia_contact_mapping_params = {
      :header_lines_count=>"0", 
      :map=>{
        "1"=>{:name=>"", :field=>"", :tr=>"As-is", :model=>""}, 
        "2"=>{:name=>"", :field=>"", :tr=>"As-is", :model=>""}, 
        "3"=>{:name=>"", :field=>"", :tr=>"As-is", :model=>""}, 
        "4"=>{:name=>"", :field=>"first_name", :tr=>"As-is", :model=>"Party"}, 
        "5"=>{:name=>"", :field=>"last_name", :tr=>"As-is", :model=>"Party"}, 
        "6"=>{:name=>"", :field=>"company_name", :tr=>"As-is", :model=>"Party"}, 
        "7"=>{:name=>"", :field=>"position", :tr=>"As-is", :model=>"Party"}, 
        "8"=>{:name=>"", :field=>"notes", :tr=>"As-is", :model=>"Party"}, 
        "9"=>{:name=>"Main", :field=>"line1", :tr=>"As-is", :model=>"AddressContactRoute"}, 
        "10"=>{:name=>"", :field=>"", :tr=>"As-is", :model=>""}, 
        "11"=>{:name=>"Main", :field=>"city", :tr=>"As-is", :model=>"AddressContactRoute"}, 
        "12"=>{:name=>"Main", :field=>"state", :tr=>"As-is", :model=>"AddressContactRoute"}, 
        "13"=>{:name=>"Main", :field=>"zip", :tr=>"As-is", :model=>"AddressContactRoute"}, 
        "22"=>{:name=>"", :field=>"", :tr=>"As-is", :model=>""}, 
        "14"=>{:name=>"Main", :field=>"number", :tr=>"As-is", :model=>"PhoneContactRoute"}, 
        "15"=>{:name=>"", :field=>"", :tr=>"As-is", :model=>""}, 
        "16"=>{:name=>"Main", :field=>"email_address", :tr=>"As-is", :model=>"EmailContactRoute"}, 
        "17"=>{:name=>"Office", :field=>"number", :tr=>"As-is", :model=>"PhoneContactRoute"}, 
        "18"=>{:name=>"Company", :field=>"url", :tr=>"As-is", :model=>"LinkContactRoute"}, 
        "19"=>{:name=>"", :field=>"", :tr=>"As-is", :model=>""}, 
        "20"=>{:name=>"", :field=>"", :tr=>"As-is", :model=>""}, 
        "21"=>{:name=>"", :field=>"", :tr=>"As-is", :model=>""}}, 
      :tag_list=>""}
    
    @mapper = Mapper.new(:account_id => 1)
    @mapper.mappings = Mapper.decode_mappings(bia_contact_mapping_params)
    
    @csv_rows = [] 
    CSV::Reader.parse(fixture_file_upload('/files/BIA_contacts_short.csv').read) do |row|
      @csv_rows << row
    end
    expected_row = [nil, nil, "Rania Hatz", "Rania", "Hatz", "Cambie Village BIA", "Coordinator", "-2006", nil, nil, 
      "Vancouver", "BC", "V5Z 2W5", "604.710.2954", nil, "rania.hatz@gmail.com", "604.876.9225", "www.cambievillage.com", nil, nil, 
      "Cambie Village Business Association", "c/o Anson Realty"]
    assert_equal expected_row, @csv_rows[1]    
  end
  
  def test_to_object
    imported_item = @mapper.to_object(@csv_rows[1])
    imported_item.save!
    assert_equal "Rania", imported_item.first_name
    assert_equal "Hatz", imported_item.last_name
    assert_equal "Cambie Village BIA", imported_item.company_name
    assert_equal "Coordinator", imported_item.position
    assert_match /-2006/i, imported_item.notes.first.body
    address_contact_route = imported_item.main_address
    assert_equal "Vancouver", address_contact_route.city
    assert_equal "BC", address_contact_route.state
    assert_equal "V5Z2W5", address_contact_route.zip
    assert_equal "rania.hatz@gmail.com", imported_item.main_email(true).email_address
    assert_match /604\.710\.2954/i, imported_item.main_phone.number
    assert_match /604\.876\.9225/i, imported_item.phones.find_by_name("Office").number
    assert_match /www\.cambievillage\.com/i, imported_item.links.find_by_name("Company").url
  end
end
