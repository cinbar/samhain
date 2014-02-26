require File.join(File.dirname(__FILE__), 'samhain.rb')
Dir["./app/controllers/*.rb"].each {|file| require file }
Dir["./app/helpers/*.rb"].each {|file| require file }
require 'yaml'
fn = File.dirname(File.expand_path(__FILE__)) + '/config.yml'
settings = YAML::load(File.open(fn))
run Samhain