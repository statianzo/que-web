Que::Web::SQL = {
  :dashboard_stats => %{
      SELECT count(*)                    AS total,
             count(locks.job_id)         AS running,
             sum((error_count > 0 AND locks.job_id IS NULL)::int) AS failing,
             sum((error_count = 0 AND locks.job_id IS NULL)::int) AS scheduled
      FROM que_jobs
      LEFT JOIN (
        SELECT (classid::bigint << 32) + objid::bigint AS job_id
        FROM pg_locks
        WHERE locktype = 'advisory'
      ) locks USING (job_id)
  }.freeze,
  :failing_jobs => %{
      SELECT que_jobs.*
      FROM que_jobs
      LEFT JOIN (
        SELECT (classid::bigint << 32) + objid::bigint AS job_id
        FROM pg_locks
        WHERE locktype = 'advisory'
      ) locks USING (job_id)
      WHERE locks.job_id IS NULL AND error_count > 0
      ORDER BY run_at
      LIMIT $1::int
      OFFSET $2::int
  }.freeze,
  :scheduled_jobs => %{
      SELECT que_jobs.*
      FROM que_jobs
      LEFT JOIN (
        SELECT (classid::bigint << 32) + objid::bigint AS job_id
        FROM pg_locks
        WHERE locktype = 'advisory'
      ) locks USING (job_id)
      WHERE locks.job_id IS NULL AND error_count = 0
      ORDER BY run_at
      LIMIT $1::int
      OFFSET $2::int
  }.freeze,
  :delete_job => %{
      DELETE
      FROM que_jobs
      WHERE job_id = $1::bigint
  }.freeze,
  :reschedule_job => %{
      UPDATE que_jobs
      SET run_at = $2::timestamptz
      WHERE job_id = $1::bigint
  }.freeze,
  :fetch_job => %{
      SELECT *
      FROM que_jobs
      WHERE job_id = $1::bigint
      LIMIT 1
  }.freeze,
}.freeze
