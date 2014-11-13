require "sinatra"

module Que
  class Web < Sinatra::Base
    VERSION = "0.2.1"
    PAGE_SIZE = 10

    use Rack::MethodOverride

    set :root, File.expand_path("../../../web", __FILE__)
    set :public_folder, proc { "#{root}/public" }
    set :views, proc { File.expand_path("views", root) }

    get "/" do
      stats = Que.execute SQL[:dashboard_stats]
      @dashboard = Viewmodels::Dashboard.new(stats[0])
      erb :index
    end

    get "/running" do
      worker_states = Que.worker_states
      pager = get_pager worker_states.count
      @list = Viewmodels::JobList.new(worker_states, pager)
      erb :running
    end

    get "/failing" do
      stats = Que.execute SQL[:dashboard_stats]
      pager = get_pager stats[0]["failing"]
      failing_jobs = Que.execute SQL[:failing_jobs], [pager.page_size, pager.offset]
      @list = Viewmodels::JobList.new(failing_jobs, pager)
      erb :failing
    end

    get "/scheduled" do
      stats = Que.execute SQL[:dashboard_stats]
      pager = get_pager stats[0]["scheduled"]
      scheduled_jobs = Que.execute SQL[:scheduled_jobs], [pager.page_size, pager.offset]

      @list = Viewmodels::JobList.new(scheduled_jobs, pager)
      erb :scheduled
    end

    get "/jobs/:id" do |id|
      job_id = id.to_i
      jobs = []
      if job_id > 0
        jobs = Que.execute SQL[:fetch_job], [job_id]
      end

      if jobs.empty?
        redirect to "", 303
      else
        @job = Viewmodels::Job.new(jobs.first)
        erb :show
      end
    end

    put "/jobs/:id" do |id|
      job_id = id.to_i
      if job_id > 0
        Que.execute SQL[:reschedule_job], [job_id, Time.now]
      end

      redirect request.referrer, 303
    end

    delete "/jobs/:id" do |id|
      job_id = id.to_i
      if job_id > 0
        Que.execute SQL[:delete_job], [job_id]
      end

      redirect request.referrer, 303
    end

    def get_pager(record_count)
      page = (params[:page] || 1).to_i
      Pager.new(page, PAGE_SIZE, record_count)
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
require "que/web/sql"
require "que/web/pager"
