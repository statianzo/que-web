module Que::Web::Viewmodels
  class Job < Struct.new(
      :priority, :run_at, :id, :job_class, :error_count, :last_error_message,
      :queue, :last_error_backtrace, :finished_at, :expired_at, :args, :data,
      :backend_pid)

    def initialize(job)
      members.each do |m|
        self[m] = job[m]
      end
    end

    def past_due?(relative_to = Time.now)
      run_at < relative_to
    end

    def humanized_job_class
      case job_class
      when "ActiveJob::QueueAdapters::QueAdapter::JobWrapper"
        args.first[:job_class]
      else
        job_class
      end
    end
  end
end
