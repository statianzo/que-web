require "sinatra"

module Que
  class Web < Sinatra::Base

    set :root, File.expand_path("../../../web", __FILE__)
    set :public_folder, proc { "#{root}/public" }
    set :views, proc { File.expand_path("views", root) }

    get "/" do
      job_stats = Que.job_stats
      failing_count = Que.execute("SELECT count(*) FROM que_jobs WHERE error_count > 0")[0]["count"]
      @dashboard = Viewmodels::Dashboard.new(job_stats, failing_count)
      erb :index
    end

    helpers do
      def root_path
        "#{env['SCRIPT_NAME']}/"
      end
    end
  end
end

require "que/web/viewmodels"
