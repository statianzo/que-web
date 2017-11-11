require "sinatra/base"
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
      stats = Que.execute SQL[:dashboard_stats], [search]
      @dashboard = Viewmodels::Dashboard.new(stats[0])
      erb :index
    end

    get "/running" do
      worker_states = search_running Que.worker_states
      pager = get_pager worker_states.count
      @list = Viewmodels::JobList.new(worker_states, pager)
      erb :running
    end

    get "/failing" do
      stats = Que.execute SQL[:dashboard_stats], [search]
      pager = get_pager stats[0]["failing"]
      failing_jobs = Que.execute SQL[:failing_jobs], [pager.page_size, pager.offset, search]
      @list = Viewmodels::JobList.new(failing_jobs, pager)
      erb :failing
    end

    get "/scheduled" do
      stats = Que.execute SQL[:dashboard_stats], [search]
      pager = get_pager stats[0]["scheduled"]
      scheduled_jobs = Que.execute SQL[:scheduled_jobs], [pager.page_size, pager.offset, search]

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

        obtained_lock = with_locked_job(job_id) do
          Que.execute SQL[:reschedule_job], [job_id, run_at]

          set_flash "info", "Job #{job_id} rescheduled for #{run_at}"
        end

        unless obtained_lock
          set_flash "warning", "Job #{job_id} not rescheduled as it was already runnning"
        end
      end

      redirect request.referrer, 303
    end

    delete "/jobs/:id" do |id|
      job_id = id.to_i
      if job_id > 0
        obtained_lock = with_locked_job(job_id) do
          Que.execute SQL[:delete_job], [job_id]
          set_flash "info", "Job #{job_id} deleted"
        end

        unless obtained_lock
          set_flash "warning", "Job #{job_id} not deleted as it was already runnning"
        end
      end

      redirect request.referrer, 303
    end

    def with_locked_job(job_id)
      result = Que.execute SQL[:lock_job], [job_id]

      obtained_lock = !result.empty? && result.first[:obtained_lock]

      yield if obtained_lock

      obtained_lock
    ensure
      Que.execute SQL[:unlock_job], [job_id] if obtained_lock
    end

    def get_pager(record_count)
      page = (params[:page] || 1).to_i
      Pager.new(page, PAGE_SIZE, record_count)
    end

    def search
      return '%' unless search_param.present?
      "%#{search_param}%"
    end

    def search_running(jobs)
      return jobs unless search_param.present?
      jobs.select { |job| job.job_class.include? search_param }
    end

    def search_param
      return unless params['search'].present?
      params['search'].gsub(/[^0-9A-Za-z:]/, '')
    end

    after { session[FLASH_KEY] = {} if @sweep_flash }

    helpers do
      def root_path
        "#{env['SCRIPT_NAME']}/"
      end

      def link_to(path)
        to path_with_search(path)
      end

      def path_with_search(path)
        path += "?search=#{search_param}" if search_param.present?
        path
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
