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
  @@polling = false
  def is_polling?
    !!@@polling
  end
  
  configure :development do
    register Sinatra::Reloader
  end
  
  config_file "./config.yml"
  
  get '/' do
    "All Systems Go"
  end
  
  namespace "/scrape" do
    get "/test" do
      send_to_recruiter({job: {title: "test", source_url: "test"}})
    end
    
    get '/angel' do
      return "Sorry I'm busy" if self.is_polling?
      id_list = get_list_of_ids
      return "Failed to fetch startups" unless id_list
      startup_ids = parse_startup_ids(id_list)
      
      body = "Scraping #{startup_ids.count} companies"
      @@polling = true
      startup_ids.first(1).each do |startup_id|
        begin
          startup_json = startup(startup_id)
        rescue Exception => ex
          puts "Exeption while fetching startup info: #{ex}"
        end
        
        url = URI.parse(angel_startup_jobs_url(startup_id))
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
                startup_json: startup_json.to_json,
                timestamp: Time.now,
                json: job_json.to_json,
            }
            send_to_recruiter(job_info)
            
            body += @company_id
          end
        rescue Exception => ex
          puts "Exeption: #{ex.message} #{ex.backtrace}"
        end
        # 1000 requests per hour / 3600 seconds means if we request once every 4 seconds we shouldn't get rate limited.
        sleep(4)
      end
      @@polling = false
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
    uri = URI.parse(recruiter_jobs_url)
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json"
    request.set_form_data(job: data.to_json)
    response = http.request(request)
    response.body
  end
  
  def startup(id)
    url = URI.parse(angel_startup_url(id))
    req = Net::HTTP::Get.new(url.path)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    response = http.request(req)
    json = JSON.parse(response.body)
  end
  
  def get_list_of_ids
    url = angel_ids_url
    data = ""
    begin
      data = Nokogiri::HTML(open(url))
    rescue Exception => ex
      puts ex
    end
    data
  end
  
  def parse_startup_ids(data)
    return "" unless data
    startup_ids = data.at_css(".startup-container").attributes["data-startup_ids"].text.strip
    startup_ids.gsub! /\[(.*)\]/, '\1'
    startup_ids = startup_ids.split(",")
  end
  
  def angel_startup_url(id)
    "#{angel_api_url}/1/startups/#{id}"
  end
  
  def angel_startup_jobs_url(id)
    "#{angel_api_url}/1/startups/#{id}/jobs"
  end
  
  def angel_ids_url
    "https://angel.co/jobs?desktop=1"
  end
  
  def recruiter_jobs_url
    "#{recruiter_url}/api/jobs"
  end
  
  def angel_api_url
    settings.ANGEL_API_URL
  end
  
  def recruiter_url
    settings.RECRUITER_URL
  end
  
end