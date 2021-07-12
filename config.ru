require 'sequel'
require 'que'
require 'que/web'

DB = Sequel.connect(ENV['DATABASE_URL'])
Que.connection = DB

map '/' do
  run Que::Web
end
