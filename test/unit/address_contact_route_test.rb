require File.dirname(__FILE__) + '/../test_helper'

class AddressContactRouteTest < Test::Unit::TestCase
  context "A duplicate of an AddressContactRoute" do
    context "that has value on its attributes" do
      setup do
        @address = AddressContactRoute.new(:line1 => "line1", :line2 => "line2",
            :line3 => "line3", :city => "city", :state => "state",
            :country => "country", :zip => "zip", :name => "name",
            :routable => Party.new)
        @dup = @address.dup
      end

      should "has the same hash as the original" do
        assert @address.eql?(@dup) && @address.hash == @dup.hash,
            "#hash property not preserved"
      end

      should "not copy routable" do
        assert_nil @dup.routable
      end

      should "copy line1 attribute correctly" do
        assert_equal "Line1", @dup.line1
      end

      should "copy line2 attribute correctly" do
        assert_equal "Line2", @dup.line2
      end

      should "copy line3 attribute correctly" do
        assert_equal "Line3", @dup.line3
      end

      should "copy city attribute correctly" do
        assert_equal "City", @dup.city
      end

      should "copy state attribute correctly" do
        assert_equal "STATE".downcase, @dup.state.downcase
      end

      should "copy country attribute correctly" do
        assert_equal "COUNTRY".downcase, @dup.country.downcase
      end

      should "copy zip attribute correctly" do
        assert_equal "ZIP", @dup.zip
      end

      should "copy name attribute correctly" do
        assert_equal "Name", @dup.name
      end

      should "be equal with the original object" do
        assert_equal @address, @dup
      end
    end

    context "that has blank fields" do
      setup do
        Configuration.set_default(:default_city, "")
        Configuration.set_default(:default_state, "")
        Configuration.set_default(:default_country, "")
        @address = AddressContactRoute.new(:line1 => "", :line2 => "",
            :line3 => "", :city => "", :state => "",
            :country => "", :zip => "", :name => "",
            :routable => Party.new)
        @dup = @address.dup
      end

      should "not copy routable" do
        assert_nil @dup.routable
      end

      should "set line1 to nil" do
        assert_nil @dup.line1
      end

      should "set line2 to nil" do
        assert_nil @dup.line2
      end

      should "set line3 to nil" do
        assert_nil @dup.line3
      end

      should "set city to nil" do
        assert_nil @dup.city
      end

      should "set state to blank" do
        assert_equal "", @dup.state
      end

      should "set country to blank" do
        assert_equal "", @dup.country
      end

      should "set zip to nil" do
        assert_nil @dup.zip
      end

      should "set name to nil" do
        assert_nil @dup.name
      end

      should "be equal to the original" do
        assert_equal @address, @dup
      end
    end

    context "that has nil value on its fields" do
      setup do
        @address = AddressContactRoute.new(:line1 => nil, :line2 => nil,
            :line3 => nil, :city => nil, :state => nil,
            :country => nil, :zip => nil, :name => nil,
            :routable => Party.new)
        @dup = @address.dup
      end

      should "not copy routable from nil" do
        assert_nil @dup.routable
      end

      should "set line1 to nil" do
        assert_nil @dup.line1
      end

      should "set line2 to nil" do
        assert_nil @dup.line2
      end

      should "set line3 to nil" do
        assert_nil @dup.line3
      end

      should "set city to nil" do
        assert_nil @dup.city
      end

      should "set state to blank" do
        assert_equal "", @dup.state
      end

      should "set country to blank" do
        assert_equal "", @dup.country
      end

      should "set zip to nil" do
        assert_nil @dup.zip
      end

      should "set name to nil" do
        assert_nil @dup.name
      end

      should "be equal to the original" do
        assert_equal @address, @dup
      end
    end
  end

  context "New AddressContactRoute" do
    context "in unknown country" do
      setup do
        @address = AddressContactRoute.new
      end

      should "be instantiated properly" do
        assert_not_nil @address, "address should have been instantiated"
      end

      should "have nil line1" do
        assert_nil @address.line1, "address' line1 should be nil"
      end

      should "have nil line2" do
        assert_nil @address.line2, "address' line2 should be nil"
      end

      should "have nil line3" do
        assert_nil @address.line3, "address' line3 should be nil"
      end

      should "have nil city" do
        assert_nil @address.city, "address' city should be nil"
      end

      should "have blank state" do
        assert_equal "", @address.state, "address' state should be empty"
      end

      should "have blank country" do
        assert_equal "", @address.country, "address' country should be empty"
      end
      
      should "have nil zip" do
        assert_nil @address.zip, "address' zip should be nil"
      end
      
      should "have blank array as address format" do
        assert_equal [], @address.format, "address' formatting does not respect proper format"
      end
    end

    context "in canada" do
      setup do
        @address = AddressContactRoute.new(:country => "canada")
      end

      should "instantiate address properly" do
        assert_not_nil @address, "address should have been instantiated"
      end

      should "have nil line1" do
        assert_nil @address.line1, "address' line1 should be nil"
      end

      should "have nil line2" do
        assert_nil @address.line2, "address' line2 should be nil"
      end

      should "have nil line3" do
        assert_nil @address.line3, "address' line3 should be nil"
      end

      should "have nil city" do
        assert_nil @address.city, "address' city should be nil"
      end

      should "have blank state" do
        assert_equal "", @address.state, "address' state should be empty"
      end

      should "have CAN as country" do
        assert_equal "CAN", @address.country, "address' country should be Canada"
      end

      should "have nil zip" do
        assert_nil @address.zip, "address' zip should be nil"
      end

      should "return ['Canada'] as format" do
        assert_equal ["Canada"], @address.format, "address' formatting does not respect proper format"
      end
    end

    context "in US" do
      setup do
        @address = AddressContactRoute.new(:country => "usa")
      end

      should "instantiate address properly" do
        assert_not_nil @address, "address should have been instantiated"
      end

      should "have nil line1" do
        assert_nil @address.line1, "address' line1 should be nil"
      end

      should "have nil line2" do
        assert_nil @address.line2, "address' line2 should be nil"
      end

      should "have nil line3" do
        assert_nil @address.line3, "address' line3 should be nil"
      end

      should "have nil city" do
        assert_nil @address.city, "address' city should be nil"
      end

      should "have blank state" do
        assert_equal "", @address.state, "address' state should be empty"
      end

      should "have USA as country" do
        assert_equal "USA", @address.country, "address' country should be USA"
      end
      
      should "have nil zip" do
        assert_nil @address.zip, "address' zip should be nil"
      end

      should "return ['USA'] as format" do
        assert_equal ["USA"], @address.format, "address' formatting does not respect proper format"
      end
    end

    context "with coded country" do
      setup do
        @address = AddressContactRoute.new(:country => 'ABC')
      end

      should "set the coded country correctly" do
        assert_equal 'ABC'.downcase, @address.country.downcase 
      end
    end

    context "with coded state" do
      setup do
        @address = AddressContactRoute.new(:state => 'JLS')
      end

      should "set the coded country correctly" do
        assert_equal 'JLS'.downcase, @address.state.downcase
      end
    end

    context "initializing with" do
      context "canadian postal code" do
        setup do
          @address = AddressContactRoute.new(:country => 'CAN', :zip => 'j1k     2l1')
        end

        should "format the postal code correctly" do
          assert_equal 'J1K 2L1', @address.zip
        end
      end

      context "us postal code" do
        setup do
          @address = AddressContactRoute.new(:country => 'USA', :zip => '12345')
        end

        should "format the postal code correctly" do
          assert_equal '12345', @address.zip
        end
      end
    end

    context "long US zip code" do
      setup do
        @address = AddressContactRoute.new(:country => 'USA', :zip => '123456789')
      end

      should "format the zip code properly" do
        assert_equal '12345-6789', @address.zip
      end
    end

    context "canadian address" do
      setup do
        @address = AddressContactRoute.new( :line1 => '123 Some St', :zip => 'j1d 2n2',
                                  :city => "truck city",
                                  :country => 'CAN', :state => 'ON',
                                  :name => 'X')
      end

      should "return the correct format" do
        assert_equal ['123 Some St', 'Truck City ON  J1D 2N2', "Canada"], @address.format
      end
    end

    context "us address" do
      setup do
        @address = AddressContactRoute.new( :line1 => '5332 Manhatan', :zip => '123456789',
                                  :city => 'New York', :country => 'USA', :state => 'DC',
                                  :name => 'X')
      end

      should "return the correct address format" do
        assert_equal ['5332 Manhatan', 'New York DC  12345-6789', 'USA'], @address.format
      end
    end
  end

  context "Geocode testing" do
    setup do
      @geocode1 = Geocode.create!(:longitude => 34.33, :latitude => 23.23, :zip => "V1VE2E", 
        :city =>"van", :state => "bc", :country => "canada")
      @geocode2 = Geocode.create!(:longitude => 56.12, :latitude => -10.42, :zip => "12345", 
        :city =>"van", :state => "bc", :country => "canada")
    end

    context "on address with valid zip" do
      setup do
        @address_with_valid_zip = AddressContactRoute.create!(:line1 => "", :line2 => "",
            :line3 => "", :city => "", :state => "",
            :country => "", :zip => "V1VE2E", :name => "",
            :routable => Party.find(:first), :account => Account.find(:first))
      end

      should "be found nearest a point" do
        assert_include @address_with_valid_zip, AddressContactRoute.nearest(@geocode1.latitude, @geocode1.longitude)
      end

      should "be within 10 kilometers of a point" do
        assert_include @address_with_valid_zip, AddressContactRoute.within(10, :unit => :kilometers, :latitude => @geocode1.latitude, :longitude => @geocode1.longitude)
      end

      should "NOT be within 10 kilometers of a point on the other side of the globe" do
        assert_not_include @address_with_valid_zip, AddressContactRoute.within(10, :unit => :kilometers, :latitude => -@geocode1.latitude, :longitude => -@geocode1.longitude)
      end

      should "make available distance in miles when asking for nearest" do
        assert_respond_to AddressContactRoute.nearest(@geocode1.latitude, @geocode1.longitude).first, :distance_in_miles
      end

      should "make available distance in kilometers when asking for nearest" do
        assert_respond_to AddressContactRoute.nearest(@geocode1.latitude, @geocode1.longitude, :unit => :km).first, :distance_in_kilometers
      end

      should "make available distance in miles when asking for within" do
        assert_respond_to AddressContactRoute.within(10, :unit => :miles, :latitude => @geocode1.latitude, :longitude => @geocode1.longitude).first, :distance_in_miles
      end

      should "make available distance in kilometers when asking for within" do
        assert_respond_to AddressContactRoute.within(10, :unit => :kilometers, :latitude => @geocode1.latitude, :longitude => @geocode1.longitude).first, :distance_in_kilometers
      end

      should "have Geocode's longitude" do
        assert_equal @geocode1.longitude, @address_with_valid_zip.longitude
      end

      should "have Geocode's latitude" do
        assert_equal @geocode1.latitude, @address_with_valid_zip.latitude
      end

      context "after update with invalid zip" do
        setup do
          @address_with_valid_zip.update_attribute("zip", "98765")
        end

        should "have reset latitude to nil" do
          assert_nil @address_with_valid_zip.longitude
        end

        should "have reset longitude to nil" do
          assert_nil @address_with_valid_zip.latitude
        end
      end
    end

    context "an address with unknown (but close) zip" do
      setup do
        @addr = AddressContactRoute.create!(:zip => @geocode1.zip.succ, :routable => parties(:bob), :account => accounts(:wpul))
      end

      should "have the longitude of a 'close enough' zip" do
        assert_equal @geocode1.longitude, @addr.longitude
      end

      should "have the latitude of a 'close enough' zip" do
        assert_equal @geocode1.latitude, @addr.latitude
      end
    end

    context "on address with unknown zip" do
      setup do
        @address_with_invalid_zip = AddressContactRoute.create!(:line1 => "", :line2 => "",
            :line3 => "", :city => "", :state => "",
            :country => "", :zip => "98754", :name => "",
            :routable => Party.find(:first), :account => Account.find(:first))
      end

      should "have nil latitude" do
        assert_nil @address_with_invalid_zip.latitude
      end

      should "have nil longitude" do
        assert_nil @address_with_invalid_zip.longitude
      end

      context "after update with valid zip" do
        setup do
          @address_with_invalid_zip.update_attribute("zip", "12345")
        end

        should "have Geocode's latitude" do
          assert_equal @geocode2.latitude, @address_with_invalid_zip.latitude
        end

        should "have Geocode's longitude" do
          assert_equal @geocode2.longitude, @address_with_invalid_zip.longitude
        end
      end
    end
  end
end
