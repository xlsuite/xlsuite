require File.dirname(__FILE__) + '/../../test_helper'

class AuthenticatedUserTest < Test::Unit::TestCase
  context "A new party" do
    setup do
      @party = Party.new(:password => "password", :password_confirmation => "password")
    end

    should "be invalid when the password is too short" do
      @party.password = @party.password_confirmation = "a"
      deny @party.valid?
      assert_match /too short/, @party.errors.on(:password).inspect
    end

    should "be invalid when the confirmation does not match the password" do
      @party.password = "abc1234"
      @party.password_confirmation = "abc123"
      deny @party.valid?
      assert_match(/doesn't match confirmation/, @party.errors.on(:password).to_s) #' fix
    end
  end

  context "A newly created party" do
    setup do
      @party = accounts(:wpul).parties.create!(:password => "password", :password_confirmation => "password")
    end

    context "with permissions: :create_party, :edit_party, :view_party'" do
      setup do
        @party.append_permissions(:create_party, :view_party, :edit_party)
        @party.send :generate_effective_permissions
      end

      context "denied :create_party" do
        setup do
          @party.denied_permissions << Permission.find_by_name("create_party")
          @party.send :generate_effective_permissions
        end

        should "NOT be granted :create_party" do
          deny @party.can?(:create_party)
        end

        should "be granted :edit_party" do
          assert @party.can?(:edit_party)
        end

        should "be able to :create_party OR :edit_party" do
          assert @party.can?(:edit_party, :create_party, :any => true)
        end

        should "NOT be able to :create_party OR :edit_party" do
          deny @party.can?(:edit_party, :create_party, :all => true)
        end
      end

      should "be granted :create_party" do
        assert @party.can?(:create_party)
      end

      should "be granted :view_party" do
        assert @party.can?(:view_party)
      end

      should "be granted :edit_party" do
        assert @party.can?(:edit_party)
      end

      should "be able to :create_party OR :edit_party" do
        assert @party.can?(:edit_party, :create_party, :any => true)
      end
    end

    should "generate the password_salt on save" do
      assert_not_nil @party.password_salt
    end

    should "generate the password_hash on save" do
      assert_not_nil @party.password_hash
    end

    should "NOT change the password_salt on save" do
      @salt = @party.password_salt
      @party.save!
      assert_equal @salt, @party.reload.password_salt
    end

    should "NOT change the password_hash on save" do
      @salt = @party.password_hash
      @party.save!
      assert_equal @salt, @party.reload.password_hash
    end

    should "change the password_hash when the password is changed" do
      @hash = @party.password_hash
      @party.password = @party.password_confirmation = "123main"
      @party.save!
      assert_not_equal @hash, @party.reload.password_hash
    end

    should "set @password to nil on save" do
      assert_nil @party.instance_variable_get("@password")
    end

    should "set @password_confirmation to nil on save" do
      assert_nil @party.instance_variable_get("@password_confirmation")
    end

    context "remembered for 5 days" do
      setup do
        @token = @party.remember_me!(5.days.from_now)[:value]
      end

      should "NOT be authenticable past the token's expiration date" do
        @party.token_expires_at = 5.minutes.ago
        @party.save!

        assert_raises(XlSuite::AuthenticatedUser::TokenExpired) do
          Party.authenticate_with_token!(@token)
        end
      end

      context "authenticating by token" do
        setup do
          @expires_at = @party.token_expires_at
          @party.update_attribute(:last_logged_in_at, nil)
          Party.authenticate_with_token!(@token)
        end

        should "reset the token's expiration date on the party" do
          assert @expires_at < @party.reload.token_expires_at,
            "New token expiration date should be in the future:\nold: #{@expires_at.to_s(:db)}, new: #{@party.token_expires_at.to_s(:db)}"
        end

        should "set the last_logged_in_at time" do
          assert_not_nil @party.reload.last_logged_in_at
        end
      end

      context "forgotten" do
        setup do
          @party.forget_me!
          @party.reload
        end

        should "set the party's token to nil" do
          assert_nil @party.token
        end

        should "set the token's expiration date to nil" do
          assert_nil @party.token_expires_at
        end
      end
    end

    context "An archived party" do
      setup do
        @party = parties(:bob)
        @token = @party.remember_me!(30.days.from_now)
        @party.archive!
      end

      should "NOT be authenticable by username and password" do
        assert_raises(XlSuite::AuthenticatedUser::UnknownUser) do
          Party.send(:authenticate_with_email_and_password!, "bob@test.com", "test")
        end
      end

      should "NOT be authenticable by token" do
        assert_raises(XlSuite::AuthenticatedUser::UnknownUser) do
          Party.authenticate_with_token!(@token[:value])
        end
      end
    end

    context "An existing party" do
      setup do
        @party = parties(:bob)
      end

      context "authenticating by email/password" do
        setup do
          @party.update_attribute(:last_logged_in_at, nil)
          Party.send(:authenticate_with_email_and_password!, "bob@test.com", "test")
        end

        should "set the last_logged_in_at date" do
          assert_not_nil @party.reload.last_logged_in_at
        end
      end

      should "NOT authenticate with a bad email" do
        assert_raises(XlSuite::AuthenticatedUser::UnknownUser) do
          Party.send(:authenticate_with_email_and_password!, "idontexist@test.com", "somerandompassword")
        end
      end

      should "NOT authenticate with a bad password" do
        assert_raises(XlSuite::AuthenticatedUser::BadAuthentication) do
          Party.send(:authenticate_with_email_and_password!, "bob@test.com", "bad pass")
        end
      end

      should "authenticate with an alternate email address" do
        EmailContactRoute.create!(:name => "Alternate", :address => "bobby@nowhere.com", :routable => @party)
        assert_nothing_raised do
          Party.send(:authenticate_with_email_and_password!, "bobby@nowhere.com", "test")
        end
      end
    end
  end

  context "A party just signing up" do
    setup do
      @party = accounts(:wpul).parties.signup!(:email_address => {:email_address => "sam@gamgee.net"},
        :party => {:first_name => "Francois", :confirmation_token => "asdf",
          :confirmation_token_expires_at => (@when = 24.hours.from_now)}, 
          :confirmation_url => %Q!http://url/!)
    end

    should "be saved" do
      deny @party.new_record?
    end

    should "have a confirmation token" do
      assert_not_nil @party.confirmation_token
    end

    should "have a valid UUID in the confirmation token" do
      assert_nothing_raised do
        UUID.parse(@party.confirmation_token)
      end
    end

    should "have a confirmation token expiration time" do
      assert_kind_of Time, @party.confirmation_token_expires_at
    end

    should "have 1 E-Mail contact route" do
      assert_equal ["sam@gamgee.net"], @party.email_addresses(true).map(&:email_address)
    end

    should "have stored the first name" do
      assert_equal "Francois", @party.first_name
    end

    should "have replaced the confirmation token attack" do
      assert_not_equal "asdf", @party.confirmation_token
    end

    should "have replaced the confirmation token expiry time attack" do
      assert_equal @when.to_s, @party.confirmation_token_expires_at.to_s
    end

    context "confirming the registration" do
      should "return the original party when using the right token" do
        assert_equal @party, @party.attempt_confirmation_token_authentication!(@party.confirmation_token)
      end

      should "raise a ConfirmationTokenExpired exception when the confirmation token is expired" do
        @party.update_attribute(:confirmation_token_expires_at, 5.minutes.ago)
        assert_raises(XlSuite::AuthenticatedUser::ConfirmationTokenExpired) do
          @party.attempt_confirmation_token_authentication!(@party.confirmation_token)
        end
      end

      should "raise an InvalidConfirmationToken exception when the token is empty" do
        assert_raise XlSuite::AuthenticatedUser::InvalidConfirmationToken do
          @party.attempt_confirmation_token_authentication!("")
        end
      end

      should "raise an InvalidConfirmationToken exception when the token is nil" do
        assert_raise XlSuite::AuthenticatedUser::InvalidConfirmationToken do
          @party.attempt_confirmation_token_authentication!(nil)
        end
      end

      should "raise an BadConfirmationToken exception when the token is unknown" do
        assert_raise XlSuite::AuthenticatedUser::BadConfirmationToken do 
          @party.attempt_confirmation_token_authentication!("234")      
        end
      end

      should "raise an UnknownUser exception when the party was archived" do
        @party.archive!
        assert_raise XlSuite::AuthenticatedUser::UnknownUser do
          @party.attempt_confirmation_token_authentication!("2309230")
        end
      end
    end

    should "raise an InvalidConfirmationToken when the confirmation token is unknown" do
      assert_raises(XlSuite::AuthenticatedUser::InvalidConfirmationToken) do
        @party.authorize!(:confirmation_token => "1234", :attributes => {:first_name => "changed!", :last_name => "transform!"})    
      end
    end

    should "record changed attributes in the authorization request" do
      @party.authorize!(:confirmation_token => @party.confirmation_token, :attributes => {:first_name => "changed!"})
      @party.reload

      assert_equal "changed!", @party.first_name
    end  

    should "set last_logged_in_at" do
      @party.update_attribute(:last_logged_in_at, nil)
      @party.authorize!(:confirmation_token => @party.confirmation_token, :attributes => {:first_name => "changed!", :last_name => "transform!"})

      assert_not_nil @party.reload.last_logged_in_at
    end

    context "authorizing the confirmation" do
      setup do
        @party.authorize!(:confirmation_token => @party.confirmation_token, :attributes => {:first_name => "changed!", :last_name => "transform!"})
        @party.reload
      end

      should "clear the confirmation token" do
        assert_nil @party.confirmation_token
      end

      should "clear the confirmation token expiry date" do
        assert_nil @party.confirmation_token_expires_at
      end
    end
  end

  context "A party signing up in the context of a create scope" do
    setup do
      Party.with_scope(:create => {:created_by_id => parties(:bob).id}) do
        @party = accounts(:wpul).parties.signup!(:party => {:first_name => "Francois"}, 
        :email_address => {:email_address => "test@xltester.com"}, 
        :confirmation_url => %Q!http://url/!)
      end

      @party.reload
    end

    should "respect the :created_by_id scope" do
      assert_equal parties(:bob).id, @party.created_by_id
    end

    should "respect the account scope" do
      assert_equal accounts(:wpul).id, @party.account_id
    end

    should "have copied the values" do
      assert_equal "Francois", @party.first_name
    end
  end

  context "A party part of a group hierarchy" do
    # Creating a group structure
    #     A
    #     /\
    #    B  C
    #       /\
    #      D  E
    #         /\
    #        F  G

    setup do
      @party = build_party
      @group_a = Group.create!(:name => "A", :account => @party.account )
      @group_b = Group.create!(:name => "B", :parent_id => @group_a.id, :account => @party.account )
      @group_c = Group.create!(:name => "C", :parent_id => @group_a.id, :account => @party.account )
      @group_d = Group.create!(:name => "D", :parent_id => @group_c.id, :account => @party.account )
      @group_e = Group.create!(:name => "E", :parent_id => @group_c.id, :account => @party.account )
      @group_f = Group.create!(:name => "F", :parent_id => @group_e.id, :account => @party.account )
      @group_g = Group.create!(:name => "G", :parent_id => @group_e.id, :account => @party.account )
      assert @party.groups << @group_d
      assert @party.groups << @group_e
    end

    should "find groups by name when a Group" do
      assert  @party.member_of?(@group_a)
      deny    @party.member_of?(@group_b)
      assert  @party.member_of?(@group_c)
      assert  @party.member_of?(@group_d)
      assert  @party.member_of?(@group_e)
      deny    @party.member_of?(@group_f)
      deny    @party.member_of?(@group_g)
    end

    should "raise an ArgumentError when a String is passed" do
      assert_raises(ArgumentError) do
        @party.member_of?(@group_a.name)
      end
    end

    should "raise an ArgumentError when a Symbol is passed" do
      assert_raises(ArgumentError) do
        @party.member_of?(@group_a.name)
      end
    end

    should "never be part of the nil group" do
      deny    @party.member_of?(nil)
    end
  end
end
