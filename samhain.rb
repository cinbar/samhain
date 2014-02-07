require 'sinatra'

class Samhain < Sinatra::Base
  
  get '/' do
    "Go Time"
  end
  
end