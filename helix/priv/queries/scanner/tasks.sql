--------------------------------------------------------------------------------
----------------------------------- SELECTS ------------------------------------
--------------------------------------------------------------------------------

-- :by_completion_date_lte
SELECT *
FROM tasks
WHERE completion_date <= ?;

--------------------------------------------------------------------------------
----------------------------------- INSERTS ------------------------------------
--------------------------------------------------------------------------------

-- :__insert
INSERT INTO tasks (
  instance_id,
  run_id,
  entity_id,
  server_id,
  type,
  target_id,
  target_sub_id,
  scheduled_at,
  completion_date,
  next_backoff,
  failed_attempts
)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
RETURNING *;

--------------------------------------------------------------------------------
----------------------------------- DELETES ------------------------------------
--------------------------------------------------------------------------------

-- NOTE: These DELETEs are unused due to CASCADE DELETE on the Instance side

-- :delete_by_entity_server
DELETE FROM tasks WHERE entity_id = ? AND server_id = ?;

-- :delete_by_tunnel
DELETE FROM TASKS WHERE instance_id IN (
  SELECT id FROM Instances WHERE tunnel_id = ?
);
