require 'sinatra'
require 'sinatra/namespace'
require 'sinatra/config_file'
require "sinatra/reloader" if development?
require 'net/http'
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
  
  namespace "/scrape" do
    get "/test" do
      send_to_recruiter({job: {title: "test", source_url: "test"}.to_json}.to_json)
    end
    
    get '/angel' do
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
      startup_ids.first(1).each do |startup_id|
        puts "scraping #{startup_id}"
        url = URI.parse("#{ANGEL_API_URL}/1/startups/#{startup_id}/jobs")
        begin 
          req = Net::HTTP::Get.new(url.path)
          http = Net::HTTP.new(url.host, url.port)
          http.use_ssl = true
          response = http.request(req)
          
          job_info = {
            job: {
              source_url: url,
              source_id: startup_id,
              timestamp: Time.now,
              json: response.body,
            }
          }
          puts job_info
          send_to_recruiter(job_info)
          job_info
        rescue Exception => ex
          puts "Exeption: #{ex}"
        end
      end
      body += job_info.to_s if job_info
      body
    end
  end
  
  
  namespace "/api" do
    get "/" do
      App::Helpers::LinkedIn.authorize
    end
  end
  
  def send_to_recruiter(data)
    uri = URI.parse("http://localhost:3000/jobs")
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json"
    request.set_form_data(data)
    response = http.request(request)
    response.body
  end
  
end