require 'sinatra/base'
module App
  module Helpers
    module BaseAuth
      def authorized?
        session[:authorized]
      end

      def authorize!
        redirect '/' unless authorized?
      end

      def logout!
        session[:authorized] = false
      end
    end
  end
end