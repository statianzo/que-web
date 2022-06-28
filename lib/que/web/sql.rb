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
    SELECT count(*) AS total,
    count(locks.job_id) AS running,
    coalesce(sum((COALESCE(locks.job_id::varchar, finished_at::varchar, expired_at::varchar) is NULL AND run_at <= now())::int), 0) AS queued,
    coalesce(sum((COALESCE(locks.job_id::varchar, finished_at::varchar, expired_at::varchar) is NULL AND run_at > now() AND (error_count = 0 OR chi_remote_events.processed_at IS NOT NULL))::int), 0) AS scheduled,
    coalesce(sum((COALESCE(locks.job_id::varchar, finished_at::varchar, expired_at::varchar, chi_remote_events.processed_at::varchar) is NULL AND chi_remote_events.id is NOT NULL AND error_count > 0 AND run_at > now())::int), 0) AS failing,
    coalesce(sum((error_count > 0 AND finished_at is not NULL)::int), 0) AS errored,
    coalesce(sum((locks.job_id IS NULL AND expired_at is NOT NULL)::int), 0) AS failed
    FROM que_jobs
    LEFT JOIN (
      SELECT (classid::bigint << 32) + objid::bigint AS job_id
      FROM pg_locks
      WHERE locktype = 'advisory'
    ) locks ON (que_jobs.id=locks.job_id)
    LEFT JOIN chi_remote_events on (CASE WHEN que_jobs.args->>0~E'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN (que_jobs.args->>0)::uuid ELSE NULL END) = chi_remote_events.id
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
  # Failing - Any unfinished/not expired job that is not running, has errors and does not have a completed remote_event and is future scheduled
  failing_jobs: <<-SQL.freeze,
    SELECT que_jobs.*
    FROM que_jobs
    LEFT JOIN (
      SELECT (classid::bigint << 32) + objid::bigint AS job_id
      FROM pg_locks
      WHERE locktype = 'advisory'
    ) locks ON (que_jobs.id=locks.job_id)
    LEFT JOIN chi_remote_events on (CASE WHEN que_jobs.args->>0~E'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN (que_jobs.args->>0)::uuid ELSE NULL END) = chi_remote_events.id
    WHERE COALESCE(locks.job_id::varchar, finished_at::varchar, expired_at::varchar, chi_remote_events.processed_at::varchar) is NULL
      AND run_at > now()
      AND error_count > 0
      AND (
        job_class ILIKE ($3)
        OR que_jobs.args #>> '{0, job_class}' ILIKE ($3)
      )
    ORDER BY run_at, id
    LIMIT $1::int
    OFFSET $2::int
  SQL
  # Errored - Any finished job with errors
  errored_jobs: <<-SQL.freeze,
    SELECT que_jobs.*
    FROM que_jobs
    LEFT JOIN (
      SELECT (classid::bigint << 32) + objid::bigint AS job_id
      FROM pg_locks
      WHERE locktype = 'advisory'
    ) locks ON (que_jobs.id=locks.job_id)
    WHERE error_count > 0 AND finished_at is not NULL
      AND job_class LIKE ($3)
    ORDER BY finished_at
    LIMIT $1::int
    OFFSET $2::int
  SQL
  # Queued - Any unfinished/not expired job that is not running and is past scheduled
  queued_jobs: <<-SQL.freeze,
    SELECT que_jobs.*
    FROM que_jobs
    LEFT JOIN (
      SELECT (classid::bigint << 32) + objid::bigint AS job_id
      FROM pg_locks
      WHERE locktype = 'advisory'
    ) locks ON (que_jobs.id=locks.job_id)
    WHERE COALESCE(locks.job_id::varchar, finished_at::varchar, expired_at::varchar) is NULL
      AND run_at <= now()
      AND (
        job_class ILIKE ($3)
        OR que_jobs.args #>> '{0, job_class}' ILIKE ($3)
      )
    ORDER BY run_at, id
    LIMIT $1::int
    OFFSET $2::int
  SQL
  # Scheduled - Any unfinished/not expired job that is not running, has no errors OR has a completed remote_event, and is future scheduled
  scheduled_jobs: <<-SQL.freeze,
    SELECT que_jobs.*
    FROM que_jobs
    LEFT JOIN (
      SELECT (classid::bigint << 32) + objid::bigint AS job_id
      FROM pg_locks
      WHERE locktype = 'advisory'
    ) locks ON (que_jobs.id=locks.job_id)
    LEFT JOIN chi_remote_events on (CASE WHEN que_jobs.args->>0~E'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN (que_jobs.args->>0)::uuid ELSE NULL END) = chi_remote_events.id
    WHERE COALESCE(locks.job_id::varchar, finished_at::varchar, expired_at::varchar) is NULL
      AND run_at > now()
      -- It has a future date and (no errors OR a completed remote_event)
      AND (error_count = 0 OR chi_remote_events.processed_at IS NOT NULL)

      AND (
        job_class ILIKE ($3)
        OR que_jobs.args #>> '{0, job_class}' ILIKE ($3)
      )
    ORDER BY run_at, id
    LIMIT $1::int
    OFFSET $2::int
  SQL
  # Failed - Any expired job
  failed_jobs: <<-SQL.freeze,
    SELECT que_jobs.*
    FROM que_jobs
    LEFT JOIN (
      SELECT (classid::bigint << 32) + objid::bigint AS job_id
      FROM pg_locks
      WHERE locktype = 'advisory'
    ) locks ON (que_jobs.id=locks.job_id)
      WHERE expired_at is not NULL
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
  fetch_remote_event: <<-SQL.freeze,
    SELECT *
    FROM chi_remote_events
    WHERE id = $1::uuid
    LIMIT 1
  SQL
}.freeze
