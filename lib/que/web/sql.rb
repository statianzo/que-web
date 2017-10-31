Que::Web::SQL = {
  dashboard_stats: <<-SQL.freeze,
    SELECT count(*)                    AS total,
           count(locks.job_id)         AS running,
           coalesce(sum((error_count > 0 AND locks.job_id IS NULL)::int), 0) AS failing,
           coalesce(sum((error_count = 0 AND locks.job_id IS NULL)::int), 0) AS scheduled
    FROM que_jobs
    LEFT JOIN (
      SELECT (classid::bigint << 32) + objid::bigint AS job_id
      FROM pg_locks
      WHERE locktype = 'advisory'
    ) locks USING (job_id)
    WHERE
      job_class LIKE ($1)
  SQL
  failing_jobs: <<-SQL.freeze,
    SELECT que_jobs.*
    FROM que_jobs
    LEFT JOIN (
      SELECT (classid::bigint << 32) + objid::bigint AS job_id
      FROM pg_locks
      WHERE locktype = 'advisory'
    ) locks USING (job_id)
    WHERE locks.job_id IS NULL AND error_count > 0 AND job_class LIKE ($3)
    ORDER BY run_at
    LIMIT $1::int
    OFFSET $2::int
  SQL
  scheduled_jobs: <<-SQL.freeze,
    SELECT que_jobs.*
    FROM que_jobs
    LEFT JOIN (
      SELECT (classid::bigint << 32) + objid::bigint AS job_id
      FROM pg_locks
      WHERE locktype = 'advisory'
    ) locks USING (job_id)
    WHERE locks.job_id IS NULL AND error_count = 0 AND job_class LIKE ($3)
    ORDER BY run_at
    LIMIT $1::int
    OFFSET $2::int
  SQL
  delete_job: <<-SQL.freeze,
    DELETE
    FROM que_jobs
    WHERE job_id = $1::bigint
    AND pg_try_advisory_lock($1::bigint)
    RETURNING pg_advisory_unlock(job_id)
  SQL
  reschedule_job: <<-SQL.freeze,
    UPDATE que_jobs
    SET run_at = $2::timestamptz
    WHERE job_id = $1::bigint
    AND pg_try_advisory_lock($1::bigint)
    RETURNING pg_advisory_unlock(job_id)
  SQL
  fetch_job: <<-SQL.freeze,
    SELECT *
    FROM que_jobs
    WHERE job_id = $1::bigint
    LIMIT 1
  SQL
}.freeze
