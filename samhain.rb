require 'sinatra'
require 'sinatra/namespace'
require 'sinatra/config_file'
require "sinatra/reloader" if development?
require 'open-uri'
require 'nokogiri'
require 'json'

class Samhain < Sinatra::Base
  register Sinatra::Namespace
  register Sinatra::ConfigFile
  configure :development do
    register Sinatra::Reloader
  end
  
  ANGEL_API_URL = "https://api.angel.co"
  config_file "./config.yml"
  
  get '/' do
    "All Systems Go"
  end
  
  get '/scrape' do
    url = "https://angel.co/jobs?desktop=1"
    begin
      data = Nokogiri::HTML(open(url))
    rescue Exception => ex
      puts ex
    end
    startup_ids = data.at_css(".startup-container").attributes["data-startup_ids"].text.strip
    startup_ids.gsub! /\[(.*)\]/, '\1'
    startup_ids = startup_ids.split(",")
    body = ""
    if true
      #body += "<p>#{startup_ids}</p>"
      startup_ids.first(5).each do |startup_id|
        puts "scraping #{startup_id}"
        url = URI.parse("#{ANGEL_API_URL}/1/startups/#{startup_id}/jobs")
        begin 
          req = Net::HTTP::Get.new(url.path)
          http = Net::HTTP.new(url.host, url.port)
          http.use_ssl = true
          response = http.request(req)
          puts response.body
          body += response.body
        rescue Exception => ex
          puts "Exeption: #{ex}"
        end
      end
    end
    body
  end
  
  
  namespace "/api" do
    get "/" do
      App::Helpers::LinkedIn.authorize
    end
  end
  
  
end