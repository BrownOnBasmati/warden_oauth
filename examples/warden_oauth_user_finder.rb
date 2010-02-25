require 'warden_oauth'
require 'warden_oauth_helpers'

include Warden::OAuth::Helpers

Warden::OAuth.access_token_user_finder :twitter do |access_token|
    unless access_token.nil?
        if user.nil?

            sql="SELECT * FROM users WHERE oauth_token = '#{access_token.token}' AND oauth_secret = '#{access_token.secret}'"
            u = User.find_by_sql sql

            if u.nil?
                twitter_user_id=access_token.params[:user_id]
                password="#{twitter_user_id}8cb364c5b3e621bf7144a58#{twitter_user_id}"
                user=User.new({
                    :email => "#{twitter_user_id}+twitter@domain.com",
                    :password => password,
                    :password_confirmation => password,
                    :oauth_token => access_token.token,
                    :oauth_secret => access_token.secret
                })
            else
                user=u[0]
            end

            # skip the confirmation. just log them in.
            if user.class.ancestors.include?(Devise::Models::Confirmable)
              user.skip_confirmation!
            end

            if user.save
              #flash[:"#{resource_name}_signed_up"] = true
              #set_flash_message :notice, :signed_up
              sign_in_and_redirect :user, user
            elsif user # put this as the first test User.find_by_sql(sql) # TODO: get from cache
              #flash[:"#{resource_name}_signed_in"] = true
              #set_flash_message :notice, :signed_in
              sign_in_and_redirect :user, user
            end
        end
    end

    # now we have a legit user
    user
end
