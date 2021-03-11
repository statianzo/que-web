require "sinatra/base"
require "cgi"

module Que
  class Web < Sinatra::Base
    PAGE_SIZE = 20
    FLASH_KEY = 'que.web.flash'.freeze

    use Rack::MethodOverride

    set :root, File.expand_path("../../../web", __FILE__)
    set :public_folder, proc { "#{root}/public" }
    set :views, proc { File.expand_path("views", root) }

    get "/" do
      stats = Que.execute SQL[:dashboard_stats], [search]
      @dashboard = Viewmodels::Dashboard.new(stats[0])
      erb :index
    end

    get "/events" do
      stats = Que.execute SQL[:event_dashboard_stats], [search]
      @events = Viewmodels::EventDashboard.new(stats[0])
      erb :events
    end

    get "/events/:id" do |id|
      event_id = id
      
      events = []
      if event_id.present?
        events = Que.execute SQL[:fetch_event], [event_id]
      end

      if events.empty?
        redirect to "", 303
      else
        @event = Viewmodels::Event.new(events.first)
        erb :show_event
      end
    end

    get "/chi_events" do
      stats = Que.execute SQL[:event_dashboard_stats], [search]
      pager = get_pager stats[0][:total]
      events = Que.execute SQL[:chi_events], [pager.page_size, pager.offset, search]
      @list = Viewmodels::EventList.new(events, pager)
      erb :chi_events
    end

    get "/chi_remote_events" do
      stats = Que.execute SQL[:event_dashboard_stats], [search]
      pager = get_pager stats[0][:remote]
      events = Que.execute SQL[:chi_remote_events], [pager.page_size, pager.offset, search]
      @list = Viewmodels::RemoteEventList.new(events, pager)
      erb :chi_remote_events
    end

    get "/running" do
      worker_states = search_running Que.job_states
      pager = get_pager worker_states.count
      @list = Viewmodels::JobList.new(worker_states, pager)
      erb :running
    end

    get "/failing" do
      stats = Que.execute SQL[:dashboard_stats], [search]
      pager = get_pager stats[0][:failing]
      failing_jobs = Que.execute SQL[:failing_jobs], [pager.page_size, pager.offset, search]
      @list = Viewmodels::JobList.new(failing_jobs, pager)
      erb :failing
    end

    get "/errored" do
      stats = Que.execute SQL[:dashboard_stats], [search]
      pager = get_pager stats[0][:errored]
      errored_jobs = Que.execute SQL[:errored_jobs], [pager.page_size, pager.offset, search]
      @list = Viewmodels::JobList.new(errored_jobs, pager)
      erb :errored
    end

    get "/scheduled" do
      stats = Que.execute SQL[:dashboard_stats], [search]
      pager = get_pager stats[0][:scheduled]
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
        updated_rows = Que.execute SQL[:reschedule_job], [job_id, run_at]
        if updated_rows.empty?
          # Didn't get the advisory lock
          set_flash "warning", "Job #{job_id} not rescheduled as it was already running"
        else
          set_flash "info", "Job #{job_id} rescheduled for #{run_at}"
        end
      end

      redirect request.referrer, 303
    end

    put "/jobs" do
      query = case params[:scope]
      when 'scheduled'
        SQL[:reschedule_all_scheduled_jobs]
      when 'failing'
        SQL[:reschedule_all_failing_jobs]
      else
        halt 400, "Unrecognized scope '#{params[:scope]}'. Valid scopes are: scheduled, failing"
      end

      run_at = Time.now
      updated_rows = Que.execute query, [run_at]

      if updated_rows.empty?
        set_flash "warning", "No jobs rescheduled"
      else
        set_flash "info", "#{updated_rows.count} jobs rescheduled for #{run_at}"
      end

      redirect request.referrer, 303
    end

    delete "/jobs/:id" do |id|
      job_id = id.to_i
      if job_id > 0
        updated_rows = Que.execute SQL[:delete_job], [job_id]

        if updated_rows.empty?
          # Didn't get the advisory lock
          set_flash "warning", "Job #{job_id} not deleted as it was already running"
        else
          set_flash "info", "Job #{job_id} deleted"
        end
      end

      redirect request.referrer, 303
    end

    delete "/jobs" do
      query = case params[:scope]
      when 'scheduled'
          SQL[:delete_all_scheduled_jobs]
      when 'failing'
        SQL[:delete_all_failing_jobs]
      else
        halt 400, "Unrecognized scope '#{params[:scope]}'. Valid scopes are: scheduled, failing"
      end

      updated_rows = Que.execute query

      if updated_rows.empty?
        set_flash "warning", "No jobs deleted"
      else
        set_flash "info", "#{updated_rows.count} jobs deleted"
      end

      redirect request.referrer, 303
    end

    def get_pager(record_count)
      page = (params[:page] || 1).to_i
      Pager.new(page, PAGE_SIZE, record_count)
    end

    after { session[FLASH_KEY] = {} if @sweep_flash }

    module Helpers
      def root_path
        "#{env['SCRIPT_NAME']}/"
      end

      def link_to(path)
        to path_with_search(path)
      end

      def path_with_search(path)
        path += "?search=#{search_param}" if search_param
        path
      end

      def search
        return '%' unless search_param
        "%#{search_param}%"
      end

      def search_running(jobs)
        return jobs unless search_param
        jobs.select { |job| job.fetch(:job_class).include? search_param }
      end

      def search_param
        sanitised = (params['search'] || '').gsub(/[^0-9a-z:]/i, '')
        return if sanitised.empty?
        sanitised
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
        return unless job.last_error_message
        line = job.last_error_message.lines.first || ''
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

      def html_escape(text)
        return if text.nil?

        CGI.escape_html(text)
      end
      alias h html_escape
    end
    helpers Helpers
  end
end

require "que/web/viewmodels"
require "que/web/sql"
require "que/web/pager"
