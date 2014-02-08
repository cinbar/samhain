require 'sinatra'
require 'sinatra/namespace'
require "sinatra/config_file"

class Samhain < Sinatra::Base
  register Sinatra::Namespace
  register Sinatra::ConfigFile
  config_file "./config.yml"
  get '/' do
    "All Systems Go"
  end
  
  namespace "/api" do
    get "/" do
      "API GET"
    end
  end
end