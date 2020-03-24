create table challenge_usage_quota (
  uuid varchar,
  action varchar,
  timestamp timestamp without time zone NOT NULL
);

PREPARE quota_count (VARCHAR, VARCHAR, VARCHAR) AS
  SELECT
    COUNT(*)
  FROM
    challenge_usage_quota
  WHERE
    challenge_usage_quota.uuid = $1
    AND action = $2
    AND timestamp between (GETDATE() - $3 ::INTERVAL)
    AND GETDATE();