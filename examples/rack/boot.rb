require 'bundler/setup'
require 'sequel'
require 'que'
require 'logger'
require 'open-uri'
require 'securerandom'

Que.logger = Logger.new(STDOUT)
Que.logger.level = Logger::INFO
Que.connection = Sequel.connect("postgres://localhost/quewebtest", max_connections: 1)
Que.migrate!(version: 4)
$stdout.sync = true

class FailJob < Que::Job
  class LameError < StandardError; end

  def run(arg1, arg2)
    raise LameError
  end
end

class SuccessJob < Que::Job
  def run(arg1, arg2)
    sleep 0.5
  end
end

class SlowJob < Que::Job
  def run(arg1, arg2)
    sleep 15
  end
end
