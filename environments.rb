configure :development do
 set :database, 'localhost'
 set :show_exceptions, true
end

configure :production do
 db = settings.db
 
 ActiveRecord::Base.establish_connection(
   :adapter  => db.adapter,
   :host     => db.host,
   :username => db.user,
   :password => db.password,
   :database => db.database,
   :encoding => 'utf8'
 )
end