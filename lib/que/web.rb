require "sinatra"

module Que
  class Web < Sinatra::Base
    use Rack::MethodOverride

    set :root, File.expand_path("../../../web", __FILE__)
    set :public_folder, proc { "#{root}/public" }
    set :views, proc { File.expand_path("views", root) }

    get "/" do
      job_stats = Que.job_stats
      failing_count = Que.execute("SELECT count(*) FROM que_jobs WHERE error_count > 0")[0]["count"]
      @dashboard = Viewmodels::Dashboard.new(job_stats, failing_count)
      erb :index
    end

    get "/failing" do
      failing_count = Que.execute("SELECT count(*) FROM que_jobs WHERE error_count > 0")[0]["count"]
      failing_jobs = Que.execute("SELECT * FROM que_jobs WHERE error_count > 0")
      @list = Viewmodels::JobList.new(failing_jobs, failing_count, 0)
      erb :failing
    end

    delete "/jobs/:id" do |id|
      job_id = id.to_i
      if job_id > 0
        Que.execute "DELETE FROM que_jobs WHERE job_id = $1::bigint", [job_id]
      end

      redirect request.referrer, 303
    end

    helpers do
      def root_path
        "#{env['SCRIPT_NAME']}/"
      end

      def active_class(pattern)
        if request.path.match pattern
          "active"
        end
      end
    end
  end
end

require "que/web/viewmodels"
