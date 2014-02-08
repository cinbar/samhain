require 'sinatra'
require 'sinatra/namespace'

class Samhain < Sinatra::Base
  register Sinatra::Namespace
  
  get '/' do
    "All Systems Go"
  end
  
  namespace "/api" do
    get "/" do
      "API GET"
    end
  end
end