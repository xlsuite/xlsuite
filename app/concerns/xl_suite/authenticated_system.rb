#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  # A module that provides authentication and authorization services to controllers.
  # This module installs a #before_filter (see XlSuite::AuthenticatedSystem::InstanceMethods#login_required)
  # and provides services to the controller through it's
  # XlSuite::AuthenticatedSystem::ClassMethods#required_permissions method.
  module AuthenticatedSystem
    class AuthenticationException < RuntimeError; end
    class AuthorizationFailureException < AuthenticationException; end

    # The name of the cookie to set when "remember me" is active.
    AUTH_TOKEN = "auth_token".freeze
    CURRENT_USER_ID = "current_user_id".freeze

    def self.included(base) #:nodoc:
      base.send :include, AuthenticatedSystem::InstanceMethods
      base.send :extend, AuthenticatedSystem::ClassMethods

      base.helper_method :current_user, :current_user?
      base.before_filter :login_from_cookie
      base.before_filter :login_required
      base.before_filter :reject_unconfirmed_user

      # Ensure all of our methods are hidden from the outside world.
      base.hide_action AuthenticatedSystem::InstanceMethods.public_instance_methods(false)
    end

    module ClassMethods
      # A method generator to define what actions are protected with what permissions.
      # The developer is responsible for ensuring there are no clashes between his
      # actions, because they are passed in a Hash, which does not guarantee the order.
      #
      # The single argument to #required_permissions may be <tt>:none</tt> or a
      # Hash of <tt>action => permissions</tt> pairs.  The keys may be a single symbol or string,
      # an array of actions, or a regular expression.
      #
      # The values of the Hash must be in a format that
      # XlSuite::AuthenticatedUser::InstanceMethods#can? will understand.
      #
      # == Examples
      #
      #  required_permissions :none 
      #    #=> do no permission checking
      #
      #  required_permissions [:edit_contact, :view_party, {:all => true}]
      #    #=> all actions will be tested against the specified permissions.
      #
      #  required_permissions :index => true
      #    #=> always allow access to the index action
      #
      #  required_permissions :index => false
      #    #=> always deny access to the index action
      #
      #  required_permissions :index => "current_user?"
      #    #=> allow access to index if current_user? returns true
      #    #   this method executes the code in the String and returns the result.
      #
      #  required_permissions :index => :view_party
      #    #=> allow access if current_user.can?(:view_party)
      #
      #  required_permissions :index => [:view_party, :edit_contact, {:any => true}]
      #    #=> allow access if current_user.can?(:view_party, :edit_contact, {:any => true})
      #
      #  required_permissions /^index/ => :view_party
      #    #=> allow access if the current action matches the regexp and current_user.can?(:view_party)
      #
      #  required_permissions %w(new edit create update) => :edit_contact
      #    #=> allow access if params[:action] is included in the array, and current_user.can?(:edit_contact)
      def required_permissions(options={})
        generated_body = []
        generated_body << "def authorized?"
        generated_body << "  returning ("

        case options
        when :none
          generated_body << "    true"

        when Hash
          generated_body << "    case self.action_name"

          options.each do |action, permissions|
            permission_clause = case permissions
            when TrueClass, FalseClass
              permissions.inspect
            when String
              permissions.to_s
            else
              "current_user? && current_user.can?(#{permissions.inspect})"
            end

            case action
            when String, Symbol
              generated_body << "    when #{action.to_s.inspect}"
            when Regexp
              generated_body << "    when #{action.inspect}"
            when Array
              generated_body << "    when #{action.inspect.gsub('[', '').gsub(']', '')}"
            else
              raise ArgumentError, "Wrong type of parameter received.  Expected key of #required_permissions to be either a Symbol, a String, a Regexp or an Array.  Received a #{action.class.name}"
            end

            generated_body << "        #{permission_clause}"
          end

          generated_body << "    else"
          generated_body << "      false # Safe by default"
          generated_body << "    end"

        else
          generated_body << "    current_user? && current_user.can?(#{options.inspect})"
        end

        generated_body << "  ) do |return_value|"
        generated_body << '    logger.debug {"#authorized? returns #{return_value.inspect}"}'
        generated_body << "  end"
        generated_body << "end"

        class_eval generated_body.join("\n")
      end
    end

    module InstanceMethods
      def session_auth_token
        XlSuite::AuthenticatedSystem::AUTH_TOKEN
      end
      
      def session_current_user_id        
        XlSuite::AuthenticatedSystem::CURRENT_USER_ID
      end
    
      # Attempt to login using a previously received authentication cookie.  If
      # the cookie is invalid or expired, the request is aborted through
      # #access_denied.
      def login_from_cookie
        return if current_user?
        return if cookies[self.session_auth_token].blank?
        # XlSuite::AuthenticatedUser enforces strict uniqueness on the #token
        # column.  That allows us to do a plain search here, instead of
        # checking the account
        user = Party.authenticate_with_token!(cookies[self.session_auth_token], current_account)

        # But as a sanity check, we'll do it anyway
        raise AuthenticationException, "Wrong cookie value for domain" unless user.account == current_account

        # We're home free !  The user has the right cookie and account
        self.current_user = user

        rescue XlSuite::AuthenticatedUser::AuthenticationException
          cookies[self.session_auth_token] = nil
          return access_denied
      end

      # A #before_filter callback that manages authentication and authorizations.
      def login_required
        return unless self.respond_to?(self.action_name)
        return unless protected?
        return access_denied unless authorized?
      end
      
      # A #before_filter callback that rejects unconfirmed users
      # Returns immediately if the user is not logged in
      def reject_unconfirmed_user
        return true unless current_user?
        unless current_user.confirmed?
          flash_failure :now, "You have not confirmed yet."
          redirect_to confirm_party_path(:id => current_user.id, :code => current_user.confirmation_token)
          return false 
        end
        return true 
      end

      # Callback to determine if the current action is protected or not.
      # This base version always answers +true+ (safe by default).
      def protected?
        true
      end

      # Callback to determine if the current user is authorized to the current action.
      # #required_permissions generates a new #authorized? that overrides this base version.
      # This version always answers +false+ (safe by default).
      def authorized?
        false
      end

      # Callback that is called when the #protected? or #authorized? return false.
      # This should redirect or render, *and must return false*, to prevent the request
      # from going on.  By default, this method redirects to #new_session_path.
      # Override as necessary.
      def access_denied(message="Unauthorized access not granted")
        store_location
        if current_user?
          respond_to do |format|
            format.html do
              return redirect_to(params[:unauthorized_redirect]) if params[:unauthorized_redirect]
              render :template => "shared/rescues/unauthorized", :layout => false, :status => "401 Unauthorized"
            end 
            format.js do
              render :update do |page|
                page << "Ext.Msg.alert('401 Unauthorized', 'You tried to access something to which you don\\'t have access');"
              end
            end
          end
        else
          flash[:notice] = message unless message.blank?
          respond_to do |format|
            format.html do
              if params[:login_redirect]
                redirect_to(params[:login_redirect])
              else
                redirect_to new_session_path
              end
            end
            format.js do
              render :update do |page|
                page << "Ext.Msg.alert('Warning', 'You\\'ve been logged out.');"
                page << "xl.maskedPanels.each(function(component){component.el.unmask();});"
              end
            end
          end
        end  
        false
      end

      # Callback to store the location we wish to return to at a later date,
      # when the user is unauthorized.  This method stores the full request URI,
      # ensuring that any query parameters are sent back after authentication.
      def store_location
        return if request.env["REQUEST_URI"] =~ REJECTED_RETURN_TO_PATH
        session[:return_to] = request.env["REQUEST_URI"] unless request.xhr?
      end

      # Determines if there is a currently recognized user.  This method is
      # automatically made available to the view.
      #
      # This method also accepts a block and yields if current_user? would
      # return +true+, and return's the block's value in this case.
      def current_user?
        has_user = session[self.session_current_user_id]
        if block_given? then
          yield if has_user
        else
          has_user
        end
      end

      # Returns the current user object, or raises AuthenticatedUser::UnknownUser
      # if it was destroyed.  This method is automatically made available to the
      # view.
      def current_user
        return self.stub_user unless current_user?
        returning @_current_user ||= Party.find(session[self.session_current_user_id]) do
          raise AuthenticatedUser::UnknownUser if @_current_user.archived?
        end
      end

      # Makes the current user a new one.  This would be used on login, or
      # alternatively, to masquerade.
      def current_user=(user)
        if user then
          session[self.session_current_user_id] = user.id
          @_current_user = user
        else
          session[self.session_current_user_id] = @_current_user = nil
        end
      end

      # Call this method to prevent the current action from continuing.
      # The current implementation raises an AuthorizationFailure exception, which is
      # caught in #rescue_action_in_public.
      def authorization_failure!(msg=nil)
        raise AuthorizationFailureException, msg
      end

      # Rescues AuthorizationFailure exceptions, and nothing else.  All other
      # exceptions are processed normally.
      def rescue_action_in_public(exception)
        case exception
        when AuthorizationFailureException
          @auth_message = exception.message
          render :file => File.join(File.dirname(__FILE__), "authorization_failure.rhtml"),
              :status => "401 Not Authorized"
        else
          super
        end
      end

      # Returns a stubbed-out implementation of XlSuite::AuthenticatedUser.
      # Actually, the stub is not even a subclass of XlSuite::AuthenticatedUser, to ensure
      # only basic queries are implemented.
      #
      # The stub implements #can? and #member_of? to return false, and #permissions
      # and #groups return an empty Array.
      def stub_user
        @_stub_user ||= returning(Object.new) do |u|
          class << u
            def id
              raise "If you are calling \#id, you are expecting to have a real user object and not a stub.  Was the user logged in ?"
            end

            def can?(*args)
              false
            end

            def permissions
              []
            end

            def groups
              []
            end

            def member_of?(*args)
              false
            end
          end
        end
      end
    end
  end
end
