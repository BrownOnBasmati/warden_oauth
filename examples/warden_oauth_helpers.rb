module Warden
  module OAuth
    module Helpers

      def warden
        request.env['warden']
      end

      # Attempts to authenticate the given scope by running authentication hooks,
      # but does not redirect in case of failures.
      def authenticate(scope)
        warden.authenticate(:scope => scope)
      end

      # Attempts to authenticate the given scope by running authentication hooks,
      # redirecting in case of failures.
      def authenticate!(scope)
        warden.authenticate!(:scope => scope)
      end

      # Check if the given scope is signed in session, without running
      # authentication hooks.
      def signed_in?(scope)
        warden.authenticate?(:scope => scope)
      end

      # Sign in an user that already was authenticated. This helper is useful for logging
      # users in after sign up.
      #
      # Examples:
      #
      #   sign_in :user, @user    # sign_in(scope, resource)
      #   sign_in @user           # sign_in(resource)
      #
      def sign_in(resource_or_scope, resource=nil)
        scope      = :user
        resource ||= resource_or_scope
        warden.set_user(resource, :scope => scope)
      end

      # Sign out a given user or scope. This helper is useful for signing out an user
      # after deleting accounts.
      #
      # Examples:
      #
      #   sign_out :user     # sign_out(scope)
      #   sign_out @user     # sign_out(resource)
      #
      def sign_out(resource_or_scope)
        scope = :user
        warden.user(scope) # Without loading user here, before_logout hook is not called
        warden.raw_session.inspect # Without this inspect here. The session does not clear.
        warden.logout(scope)
      end

      # Returns and delete the url stored in the session for the given scope. Useful
      # for giving redirect backs after sign up:
      #
      # Example:
      #
      #   redirect_to stored_location_for(:user) || root_path
      #
      def stored_location_for(resource_or_scope)
        scope = :user 
        #session.delete(:"#{scope}.return_to")
        session.delete(:".return_to")
      end

      # The default url to be used after signing in. This is used by all Devise
      # controllers and you can overwrite it in your ApplicationController to
      # provide a custom hook for a custom resource.
      #
      # By default, it first tries to find a resource_root_path, otherwise it
      # uses the root path. For a user scope, you can define the default url in
      # the following way:
      #
      #   map.user_root '/users', :controller => 'users' # creates user_root_path
      #
      #   map.resources :users do |users|
      #     users.root # creates user_root_path
      #   end
      #
      #
      # If none of these are defined, root_path is used. However, if this default
      # is not enough, you can customize it, for example:
      #
      #   def after_sign_in_path_for(resource)
      #     if resource.is_a?(User) && resource.can_publish?
      #       publisher_url
      #     else
      #       super
      #     end
      #   end
      #
      def after_sign_in_path_for(resource_or_scope)
        scope = :user 
        home_path = :"#{scope}_root_path"
        respond_to?(home_path, true) ? send(home_path) : root_path
      end

      # Method used by sessions controller to sign out an user. You can overwrite
      # it in your ApplicationController to provide a custom hook for a custom
      # scope. Notice that differently from +after_sign_in_path_for+ this method
      # receives a symbol with the scope, and not the resource.
      #
      # By default is the root_path.
      def after_sign_out_path_for(resource_or_scope)
        root_path
      end

      # Sign in an user and tries to redirect first to the stored location and
      # then to the url specified by after_sign_in_path_for.
      #
      # If just a symbol is given, consider that the user was already signed in
      # through other means and just perform the redirection.
      def sign_in_and_redirect(resource_or_scope, resource=nil, skip=false)
        scope      = :user 
        resource ||= resource_or_scope
        sign_in(scope, resource) unless skip
        #redirect_to stored_location_for(scope) #|| after_sign_in_path_for(resource)
        response.redirect stored_location_for(scope), 302 #|| after_sign_in_path_for(resource)
      end

      # Sign out an user and tries to redirect to the url specified by
      # after_sign_out_path_for.
      def sign_out_and_redirect(resource_or_scope)
        scope = :user 
        sign_out(scope)
        redirect_to after_sign_out_path_for(scope)
      end

    end
  end
end
