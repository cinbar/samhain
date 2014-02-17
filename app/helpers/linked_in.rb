require 'sinatra/base'
require 'oauth2'

module App
  module Helpers
    module LinkedIn
      STATE = SecureRandom.hex(15)
      
      def self.client
        OAuth2::Client.new(
               settings.API_KEY, 
               settings.API_SECRET, 
               :authorize_url => "/uas/oauth2/authorization?response_type=code",
               :token_url => "/uas/oauth2/accessToken",
               :site => "https://www.linkedin.com"
             )
      end

      def self.authorize
        #Redirect your user in order to authenticate
        redirect client.auth_code.authorize_url(:scope => 'r_fullprofile r_emailaddress r_network', 
                                                   :state => STATE, 
                                                   :redirect_uri => settings.REDIRECT_URI)
      end

      def self.accept
        #Fetch the 'code' query parameter from the callback
        code = params[:code] 
        state = params[:state]

        if !state.eql?(STATE)
          #Reject the request as it may be a result of CSRF
        else           
         #Get token object, passing in the authorization code from the previous step 
         token = client.auth_code.get_token(code, :redirect_uri => settings.REDIRECT_URI)

         #Use token object to create access token for user 
         #(this is required so that you provide the correct param name for the access token)
         access_token = OAuth2::AccessToken.new(client, token.token, {
           :mode => :query,
           :param_name => "oauth2_access_token",
           })

         #Use the access token to make an authenticated API call
         response = access_token.get('https://api.linkedin.com/v1/people/~')

         #Print body of response to command line window
         puts response.body

         # Handle HTTP responses
         case response
           when Net::HTTPUnauthorized
             # Handle 401 Unauthorized response
           when Net::HTTPForbidden
             # Handle 403 Forbidden response
         end
        end
      end 
    end
  end
end

