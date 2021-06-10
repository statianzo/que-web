lock_job_sql = <<-SQL.freeze
    SELECT id, pg_try_advisory_lock(id) AS locked
    FROM que_jobs
    WHERE id = $1::bigint
SQL

lock_all_failing_jobs_sql = <<-SQL.freeze
    SELECT id, pg_try_advisory_lock(id) AS locked
    FROM que_jobs
    WHERE error_count > 0 AND finished_at is NULL
SQL

lock_all_scheduled_jobs_sql = <<-SQL.freeze
    SELECT id, pg_try_advisory_lock(id) AS locked
    FROM que_jobs
    WHERE error_count = 0 AND finished_at is NULL
SQL

def reschedule_all_jobs_query(scope)
  <<-SQL.freeze
    WITH target AS (#{scope})
    UPDATE que_jobs
    SET run_at = $1::timestamptz,
        expired_at = NULL
    FROM target
    WHERE target.locked
    AND target.id = que_jobs.id and que_jobs.finished_at is NULL
    RETURNING pg_advisory_unlock(target.id)
  SQL
end

def delete_jobs_query(scope)
  <<-SQL.freeze
    WITH target AS (#{scope})
    DELETE FROM que_jobs
    USING target
    WHERE target.locked
    AND target.id = que_jobs.id
    RETURNING pg_advisory_unlock(target.id)
  SQL
end

Que::Web::SQL = {
  dashboard_stats: <<-SQL.freeze,
    SELECT count(*)                    AS total,
           count(locks.job_id)         AS running,
           coalesce(sum((error_count > 0 AND locks.job_id IS NULL AND finished_at is NULL)::int), 0) AS failing,
           coalesce(sum((error_count = 0 AND locks.job_id IS NULL AND finished_at is NULL)::int), 0) AS scheduled,
           coalesce(sum((error_count > 0 AND finished_at is not NULL)::int), 0) AS errored
    FROM que_jobs
    LEFT JOIN (
      SELECT (classid::bigint << 32) + objid::bigint AS job_id
      FROM pg_locks
      WHERE locktype = 'advisory'
    ) locks ON (que_jobs.id=locks.job_id)
    WHERE
      job_class ILIKE ($1)
      OR que_jobs.args #>> '{0, job_class}' ILIKE ($1)
  SQL
  event_dashboard_stats: <<-SQL.freeze,
    SELECT count(distinct chi_events.id) AS total,
         count(remote.id)                AS remote
    FROM chi_events
    LEFT JOIN (
      SELECT *
      FROM chi_remote_events
    ) remote ON ((remote.data->'chi_event'->>'id')::uuid = chi_events.id)
    WHERE
      chi_events.type LIKE ($1)
  SQL
  chi_events: <<-SQL.freeze,
    SELECT *
    FROM chi_events
    WHERE
      type LIKE ($3)
    ORDER BY event_order desc
    LIMIT $1::int
    OFFSET $2::int
  SQL
  chi_data_events: <<-SQL.freeze,
    SELECT *
    FROM chi_events
    WHERE
      data @> $2::jsonb
    ORDER BY event_order desc
    LIMIT $1::int
  SQL
  chi_remote_data_events: <<-SQL.freeze,
    SELECT *
    FROM chi_remote_events
    WHERE
      data @> $2::jsonb
    ORDER BY event_order desc
    LIMIT $1::int
  SQL
  chi_remote_events: <<-SQL.freeze,
    SELECT *
    FROM chi_remote_events
    WHERE
      type LIKE ($3) or gateway LIKE ($3)
    ORDER BY event_order desc
    LIMIT $1::int
    OFFSET $2::int
  SQL
  failing_jobs: <<-SQL.freeze,
    SELECT que_jobs.*
    FROM que_jobs
    LEFT JOIN (
      SELECT (classid::bigint << 32) + objid::bigint AS job_id
      FROM pg_locks
      WHERE locktype = 'advisory'
    ) locks ON (que_jobs.id=locks.job_id)
    WHERE locks.job_id IS NULL
      AND error_count > 0
      AND finished_at is NULL
      AND (
        job_class ILIKE ($3)
        OR que_jobs.args #>> '{0, job_class}' ILIKE ($3)
      )
    ORDER BY run_at, id
    LIMIT $1::int
    OFFSET $2::int
  SQL
  errored_jobs: <<-SQL.freeze,
    SELECT que_jobs.*
    FROM que_jobs
    WHERE error_count > 0 AND finished_at is not NULL AND job_class LIKE ($3)
    ORDER BY finished_at
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
    ) locks ON (que_jobs.id=locks.job_id)
    WHERE locks.job_id IS NULL
      AND error_count = 0
      AND finished_at is NULL
      AND (
        job_class ILIKE ($3)
        OR que_jobs.args #>> '{0, job_class}' ILIKE ($3)
      )
    ORDER BY run_at, id
    LIMIT $1::int
    OFFSET $2::int
  SQL
  delete_job: delete_jobs_query(lock_job_sql),
  delete_all_scheduled_jobs: delete_jobs_query(lock_all_scheduled_jobs_sql),
  delete_all_failing_jobs: delete_jobs_query(lock_all_failing_jobs_sql),
  reschedule_job: <<-SQL.freeze,
    WITH target AS (#{lock_job_sql})
    UPDATE que_jobs
    SET run_at = $2::timestamptz,
        expired_at = NULL
    FROM target
    WHERE target.locked
    AND target.id = que_jobs.id and que_jobs.finished_at is NULL
    RETURNING pg_advisory_unlock(target.id)
  SQL
  reschedule_all_scheduled_jobs: reschedule_all_jobs_query(lock_all_scheduled_jobs_sql),
  reschedule_all_failing_jobs: reschedule_all_jobs_query(lock_all_failing_jobs_sql),
  fetch_job: <<-SQL.freeze,
    SELECT *
    FROM que_jobs
    WHERE id = $1::bigint
    LIMIT 1
  SQL
  fetch_event: <<-SQL.freeze,
    SELECT *
    FROM chi_events
    WHERE id = $1::uuid
    LIMIT 1
  SQL
}.freeze
