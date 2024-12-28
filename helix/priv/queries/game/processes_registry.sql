--------------------------------------------------------------------------------
----------------------------------- INSERTS ------------------------------------
--------------------------------------------------------------------------------

-- :__insert
INSERT INTO processes_registry
  (server_id, process_id, entity_id, tgt_log_id, inserted_at)
VALUES
  (?, ?, ?, ?, ?)
RETURNING *;

--------------------------------------------------------------------------------
----------------------------------- SELECTS ------------------------------------
--------------------------------------------------------------------------------

-- :__fetch
SELECT * FROM processes_registry WHERE server_id = ? AND process_id = ?;

-- :servers_with_processes
SELECT server_id FROM processes_registry GROUP BY server_id;
