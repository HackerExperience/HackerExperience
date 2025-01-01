--------------------------------------------------------------------------------
----------------------------------- INSERTS ------------------------------------
--------------------------------------------------------------------------------

-- :__insert
INSERT INTO processes (
  entity_id,
  type,
  data,
  registry,
  status,
  resources,
  inserted_at,
  last_checkpoint_ts,
  estimated_completion_ts
  )
VALUES
  (?, ?, ?, ?, ?, ?, ?, ?, ?)
RETURNING *;
