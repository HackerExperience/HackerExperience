--------------------------------------------------------------------------------
----------------------------------- INSERTS ------------------------------------
--------------------------------------------------------------------------------

-- :__insert
INSERT INTO log_visibilities
  (server_id, log_id, revision_id, inserted_at)
VALUES
  (?, ?, ?, ?)
RETURNING *;

--------------------------------------------------------------------------------
----------------------------------- SELECTS ------------------------------------
--------------------------------------------------------------------------------
