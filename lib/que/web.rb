require "sinatra"
require "erubis"

module Que
  class Web < Sinatra::Base
    PAGE_SIZE = 10
    FLASH_KEY = 'que.web.flash'.freeze

    use Rack::MethodOverride

    set :root, File.expand_path("../../../web", __FILE__)
    set :public_folder, proc { "#{root}/public" }
    set :views, proc { File.expand_path("views", root) }
    set :erb, :escape_html => true

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
        run_at = Time.now
        Que.execute SQL[:reschedule_job], [job_id, run_at]
        set_flash "info", "Job #{job_id} rescheduled for #{run_at}"
      end


      redirect request.referrer, 303
    end

    delete "/jobs/:id" do |id|
      job_id = id.to_i
      if job_id > 0
        Que.execute SQL[:delete_job], [job_id]
        set_flash "warning", "Job #{job_id} deleted"
      end

      redirect request.referrer, 303
    end

    def get_pager(record_count)
      page = (params[:page] || 1).to_i
      Pager.new(page, PAGE_SIZE, record_count)
    end

    after { session['flash'] = {} if @sweep_flash }

    helpers do
      def root_path
        "#{env['SCRIPT_NAME']}/"
      end

      def active_class(pattern)
        if request.path.match pattern
          "active"
        end
      end

      def format_args(job)
        truncate job.args.map(&:inspect).join(', ')
      end

      def format_error(job)
        return unless job.last_error
        line = job.last_error.lines.first
        truncate line, 30
      end

      def relative_time(time)
        %{<time class="timeago" datetime="#{time.utc.iso8601}">#{time.utc}</time>}
      end

      def truncate(str, len=200)
        if str.length > len
          str[0..len] + '...'
        else
          str
        end
      end

      def flash
        @sweep_flash = true
        session[FLASH_KEY] ||= {}
      end

      def set_flash(level, val)
        hash = session[FLASH_KEY] ||= {}
        hash[level] = val
      end
    end
  end
end

require "que/web/viewmodels"
require "que/web/sql"
require "que/web/pager"
