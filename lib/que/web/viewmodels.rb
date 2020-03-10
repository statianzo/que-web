require "json"

Dir[File.expand_path('../viewmodels/*.rb', __FILE__)].each {|f| require f}
module Que::Web::Viewmodels
end
