require File.join(File.dirname(__FILE__), 'samhain.rb')
Dir["./app/controllers/*.rb"].each {|file| require file }
Dir["./app/helpers/*.rb"].each {|file| require file }
run Samhain