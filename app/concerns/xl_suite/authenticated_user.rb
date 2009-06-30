#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "digest/sha1"

module XlSuite
  # An ActiveRecord mixin that can authenticate and authorize users.
  module AuthenticatedUser
    # The base exception class.
    class AuthenticationException < RuntimeError; end

    class UnknownUser < AuthenticationException; end
    class BadAuthentication < AuthenticationException; end
    class TokenExpired < AuthenticationException; end
    class ConfirmationTokenExpired < AuthenticationException; end
    class InvalidConfirmationToken < AuthenticationException; end
    class BadConfirmationToken < AuthenticationException; end

    def self.included(base) #:nodoc:
      base.send :extend, AuthenticatedUser::ClassMethods
      base.send :include, AuthenticatedUser::InstanceMethods

      base.send :attr_accessor, :password, :email, :old_password, :confirmation_url
      base.attr_protected :password_hash, :password_salt, :token, :token_expires_at, :confirmation_token, :confirmation_token_expires_at

      base.validates_confirmation_of :password
      base.validates_length_of :password, :minimum => 6, :allow_nil => true
      base.validates_uniqueness_of :token, :allow_nil => true

      base.before_save :generate_password_salt
      base.before_save :crypt_password
      base.after_save :clear_password
      base.before_save :set_confirmed
    end

    module ClassMethods
      # Authenticates using an E-Mail address and password.  Raises UnknownUser
      # if we cannot find the E-Mail address.
      def authenticate_with_email_and_password!(email, password)
        email = EmailContactRoute.find_by_address(email)
        raise UnknownUser unless email
        raise UnknownUser unless email.routable
        
        email.routable.attempt_password_authentication!(password)
      end

      # Attempts to authenticate using the specified token.  If this token is
      # unknown, this method raises UnknownUser.
      def authenticate_with_token!(token, account)
        user = self.find(:first, :conditions => {:token => token, :account_id => account.id})
        raise UnknownUser unless user
        user.attempt_token_authentication!(token)
      end

      # Signs a new user up.  This sets #confirmation_token and #confirmation_token_expires_at.
      # The create scope is respected.
      def signup!(params={})
        self.transaction do
          attributes = params[:party] || {}
          attributes.reverse_merge!(scope(:create)) if scoped?(:create)
          returning(self.new(attributes)) do |party|
            do_signup(party, params)
          end
        end
      end
      
      # Signs up an unconfirmed user
      # Similar to signup, but does not create a new party
      def resignup!(party, params={})
        do_signup(party, params, true)
      end
      
      def gigya_signup!(params={})
        self.transaction do
          attributes = params[:party] || {}
          attributes.reverse_merge!(scope(:create)) if scoped?(:create)
          returning(self.new(attributes)) do |party|
            do_signup(party, params, true, false)
          end
        end
      end
      
      protected
      def do_signup(party, params, resignup=false, send_confirmation_email = true)
        party.confirmation_token = UUID.random_create.to_s
        party.confirmation_token_expires_at = params[:confirmation_token_expires_at] if party.confirmation_token_expires_at.blank?
        party.confirmation_token_expires_at = party.account.get_config(:confirmation_token_duration_in_seconds).from_now \
            if party.confirmation_token_expires_at.blank?

        party.tag_list = party.tag_list << "," << params[:domain].name if params[:domain]
        if params[:profile]
          party.profile = params[:profile] 
          party.profile.tag_list = party.profile.tag_list << "," << party.tag_list
          party.profile.save
        end
        party.save
        group = party.account.groups.find_by_name(Configuration.get("add_to_group_on_signup", party.account))
        party.groups << group if group
        party.account.groups.find(params[:group_ids].split(",").map(&:strip).reject(&:blank?)).to_a.each do |g|
          party.groups << g unless party.groups.include?(g)
        end if params[:group_ids]
        party.update_effective_permissions = true
        party.append_permissions(:edit_own_account)
        party.save
        party.reload
        
        party.confirmation_url = params[:confirmation_url]
        unless resignup
          party_main_email = party.main_email
          party_main_email.attributes = params[:email_address]
          
          raise ActiveRecord::RecordInvalid.new(party || party_main_email) unless party_main_email.save
        end
        
        if send_confirmation_email
          begin
            AdminMailer.deliver_signup_confirmation_email(:route => party.main_email(true),
                :confirmation_url => party.confirmation_url,
                :confirmation_token => party.confirmation_token)
          rescue
            MethodCallbackFuture.create!(:models => [party], :account => party.account, :method => :deliver_signup_confirmation_email, 
              :scheduled_at => 1.minute.from_now, 
              :params => {:confirmation_url => party.confirmation_url.call(party, party.confirmation_token), 
                          :confirmation_token => party.confirmation_token, :errored => 1})
          end
        end
      end
    end

    module InstanceMethods
      include XlSuite::Permissionable

      # The characters available for generating new passwords
      PasswordSource = "abcdefghijklmnopqrstuvwxyz1234567890".freeze

      # The total number of characters available in PasswordSource
      PasswordSourceLength = PasswordSource.length.freeze

      # Changes the user's password, confirming that we have an old 
      # password and that it matches with the prior password.
      def change_password!(options={})
        old_password = options.delete(:old_password)
        password = options.delete(:password)
        password_confirmation = options.delete(:password_confirmation)

        # TODO skipping attempt_password_authentication if old_password is nil? are you kidding?!
        self.attempt_password_authentication!(old_password) unless self.password_hash.blank?
        self.password, self.password_confirmation = password, password_confirmation
        self.save!
      end

      # Generates a new random password salt and password.  Returns the password.
      def randomize_password!
        returning "" do |passwd|
          self.password_salt = self.password_hash = nil
          6.times do
           passwd << PasswordSource[rand(PasswordSourceLength)]
          end

          self.password = self.password_confirmation = passwd
          self.save!
        end
      end

      # Deletes the cookie authentication token and the token's expiration time.
      def forget_me!
        returning self do
          self.token = self.token_expires_at = nil
          self.save!
        end
      end

      def unconfirm!(expires_at=24.hours.from_now)
        self.confirmation_token = UUID.random_create.to_s
        self.confirmation_token_expires_at = expires_at
        self.confirmed_at = nil
        self.save!
      end

      # Returns a token value that is good for cookies, which can be used to
      # authenticate by calling #authenticate_with_token!
      #
      # In fact, this method returns a Hash with two items.  The first is :value,
      # and the second is :expires.  Both together are good for a call to
      # #cookies[]=.
      def remember_me!(expires_at=30.days.from_now)
        attempts_left = 5
        begin
          self.token_expires_at = expires_at
          self.token = self.sha1("#{UUID.random_create.to_s}--#{expires_at.to_s}")
          self.save!
        rescue ActiveRecord::RecordInvalid
          raise unless self.errors.on(:token)
          raise if attempts_left == 0
          attempts_left -= 1
          retry
        end

        {:value => self.token, :expires => self.token_expires_at}
      end

      # Attempts to authenticate this AuthenticatedUser with the password.  Raises
      # UnknownUser if this user is destroyed, or BadAuthentication if the password
      # does not match.
      def attempt_password_authentication!(password)
        raise UnknownUser, "This user has been archived" if self.archived?
        raise BadAuthentication, "The passwords do not match" if self.encrypted_password(password) != self.password_hash
        self.login!
      end

      # Attempts to authenticate this AuthenticatedUser using the token.  Raises
      # UnknownUser if this user is destroyed, or TokenExpired if the token has
      # expired.
      def attempt_token_authentication!(token)
        raise UnknownUser if self.archived?
        raise TokenExpired if self.token_expires_at.blank? || self.token_expires_at < Time.now
        self.token_expires_at = 30.days.from_now
        self.login!
      end
      
      # Attempts to authenticate user using the confirmation token
      # Raises UnknownUser if the user is archived or TokenExpired if the token has expired
      def attempt_confirmation_token_authentication!(token)
        raise UnknownUser if self.archived?
        raise InvalidConfirmationToken if token.blank?
        raise ConfirmationTokenExpired if self.confirmation_token_expires_at < Time.now
        raise BadConfirmationToken unless self.confirmation_token == token
        self
      end
      
      def confirmed?
        return self.confirmed_at ? true : false
      end
      
      def confirm!
        self.confirmation_token = nil
        self.confirmation_token_expires_at = nil
        self.confirmed_at = Time.now
        self.save!
      end
      
      # An alternate method of doing confirmation token authentication.
      def confirmation_code=(token)
        logger.debug {"==> \#confirmation_code: #{token.inspect}"}
        return if token.blank?

        logger.debug {"==> attempt confirmation token authentication"}
        self.attempt_confirmation_token_authentication!(token)

        logger.debug {"==> confirmation token accepted"}
        self.confirmation_token = nil
        self.confirmation_token_expires_at = nil
      end

      # Returns the SHA1 hex digest of the value.
      def sha1(value)
        Digest::SHA1.hexdigest(value)
      end

      # Asserts that this Party can or cannot do something:
      #  party.can?(:edit_permissions) #=> false
      #  party.can?(:edit_article) #=> true
      #
      # It is possible to do multiple checks at once:
      #  party.can?(:supervise, :edit_article, :any => true)
      #  party.can?(:edit_schedule, :edit_own_schedule, :all => true)
      #
      # It is also possible to assert that none of the permissions is assigned to this party:
      #  party.can?(:supervise, :none => true) #=> false
      #
      # See Permission
      def can?(*args)
        args.flatten!
        args.compact!
        return false if args.empty?
        options = if args.last.kind_of?(Hash) then
                    args.pop
                  else
                    {:all => true}
                  end
        raise ArgumentError, "Can accept only one of :none, :all or :any in options" if options.size != 1

        permissions = args.map {|p| Permission.normalize(p)}
        return false if permissions.empty?
        
        permissions.uniq!
        permissions = permissions.map do |perm_name|
          Permission.find_by_name(perm_name)
        end
        
        permissions.compact!
        return false if permissions.empty?
        
        permission_ids = permissions.map(&:id).join(",")
        count = ActiveRecord::Base.connection().select_value(%Q~
          SELECT COUNT(*) FROM effective_permissions WHERE party_id=#{self.id} AND permission_id IN (#{permission_ids})
        ~).to_i

        if options[:any]
          return true if count > 0
        elsif options[:all]
          return true if count == permissions.size 
        elsif options[:none]
          return true if count == 0
        else
          raise ArgumentError, ":all or :any MUST be specified - none found"
        end
=begin
        return false if permissions - denied_permissions.map(&:name) != permissions

        perms = (self.permissions + self.groups.map(&:permissions)).flatten.uniq
        if options[:any] then
          perms.each do |perm|
            return true if permissions.include?(perm.name)
          end
        elsif options[:all] then
          authz = perms.map {|p| p.name}
          return true if (permissions - authz).empty?
        elsif options[:none] then
          authz = perms.map {|p| p.name}
          return true if (authz - permissions) == authz
        else
          raise ArgumentError, ":all or :any MUST be specified - none found"
        end
=end
        false
      end
      
      # Takes in a hash of confirmation_token and attributes
      # Returns self object immediately if a user has been been authorized,
      # otherwise sets confirmation_token, confirmation_token_expires_at to blank
      # and then update user attributes and save
      def authorize!(params={})
        self.class.transaction do  
          return self if self.confirmation_token.blank?
          raise InvalidConfirmationToken if self.confirmation_token != params[:confirmation_token]
          returning(self) do
            self.attributes = params[:attributes]
            self.confirmation_token = nil
            self.confirmation_token_expires_at = nil
            self.confirmed_at = Time.now
            self.login!
          end
        end
      end
      
      def member_of?(group_or_role)
        raise ArgumentError, "#{group_or_role.class.name} object type not supported, has to be Group or Role or nil" unless group_or_role.kind_of?(Group) || group_or_role.kind_of?(Role) || group_or_role.kind_of?(NilClass)
        return false if group_or_role.blank?
        object = group_or_role.class.find_by_name(group_or_role.name)
        return false if group_or_role.blank?
        
        relation_name = if group_or_role.kind_of?(Group)
                          "groups"
                        elsif group_or_role.kind_of?(Role)
                          "roles"
                        end
        
        self.send(relation_name).each do |o|
          name_list = o.ancestors.map(&:name) + [o.name]
          return true if name_list.index(object.name)
        end

        return false
      end
      
      protected
      # Changes this user's last logged in at time.
      def login!
        returning self do
          self.last_logged_in_at = Time.now.utc
          self.save!
        end
      end

      # Encrypts the password using the local salt.
      def encrypted_password(password)
        self.sha1("#{self.password_salt}--#{password}--")
      end

      # Clears @password and @password_confirmation.
      def clear_password
        self.password = self.password_confirmation = nil
      end

      # A callback to encrypt the password before save.
      def crypt_password
        return if self.password.blank?
        self.password_hash = self.encrypted_password(self.password)
      end

      # A callback to generate a password salt if none set.
      def generate_password_salt
        return unless self.password_salt.blank?
        self.password_salt = self.sha1("#{Time.now.to_s}--#{rand()}")
      end
      
      def set_confirmed
        self.confirmed = self.confirmed_at ? true : false
        true
      end
    end
  end
end
