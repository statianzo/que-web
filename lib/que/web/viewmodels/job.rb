module Que::Web::Viewmodels
  class Job < Struct.new(
    :args, :error_count, :job_class, :job_id, :last_error, :last_error,
    :pg_backend_pid, :pg_last_query, :pg_last_query_started_at, :pg_state,
    :pg_state_changed_at, :pg_transaction_started_at, :pg_waiting_on_lock,
    :priority, :queue, :run_at)

    def initialize(job)
      members.each do |m|
        self[m] = job[m.to_s]
      end
    end
  end
end
