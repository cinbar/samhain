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
    RECRUITER_URL = "http://localhost:3000"
  end
  
  configure :production do
    RECRUITER_URL = "http://offerapp.herokuapp.com"
  end
  
  ANGEL_API_URL = "https://api.angel.co"
  config_file "./config.yml"
  
  get '/' do
    "All Systems Go"
  end
  
  namespace "/scrape" do
    get "/test" do
      send_to_recruiter({job: {title: "test", source_url: "test"}})
    end
    
    get '/angel' do
      url = "https://angel.co/jobs?desktop=1"
      begin
        data = Nokogiri::HTML(open(url))
      rescue Exception => ex
        puts ex
      end
      return "Failed to fetch startups" unless data
      startup_ids = data.at_css(".startup-container").attributes["data-startup_ids"].text.strip
      startup_ids.gsub! /\[(.*)\]/, '\1'
      startup_ids = startup_ids.split(",")
    
      body = "Scraping #{startup_ids.count} companies"
      startup_ids.each do |startup_id|
        url = URI.parse("#{ANGEL_API_URL}/1/startups/#{startup_id}/jobs")
        @company_id = startup_id
        begin 
          req = Net::HTTP::Get.new(url.path)
          http = Net::HTTP.new(url.host, url.port)
          http.use_ssl = true
          response = http.request(req)
          list_of_jobs = JSON.parse(response.body)
          puts "Found #{list_of_jobs.count} jobs for #{startup_id}"
          list_of_jobs.each do |job_json|
            job_info = {
                source_url: url.path,
                source_id: "ANGEL",
                source_job_id: job_json["id"],
                source_company_id: @company_id,
                timestamp: Time.now,
                json: job_json.to_json,
            }
            send_to_recruiter(job_info)
            
            body += @company_id
          end
        rescue Exception => ex
          puts "Exeption: #{ex}"
        end
        # 1000 requests per hour / 3600 seconds means if we request once every 4 seconds we shouldn't get rate limited.
        sleep(4)
      end
      body += "Finished at #{Time.now}"
      body
    end
  end
  
  
  namespace "/api" do
    get "/" do
      App::Helpers::LinkedIn.authorize
    end
  end
  
  def send_to_recruiter(data)
    uri = URI.parse("#{RECRUITER_URL}/api/jobs")
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json"
    request.set_form_data(job: data.to_json)
    response = http.request(request)
    response.body
    #http.finish
  end
  
end