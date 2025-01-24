--------------------------------------------------------------------------------
----------------------------------- SELECTS ------------------------------------
--------------------------------------------------------------------------------

-- :__fetch
SELECT * FROM processes_registry WHERE server_id = ? AND process_id = ?;

-- :__all
SELECT * FROM processes_registry;

-- :servers_with_processes
SELECT server_id FROM processes_registry GROUP BY server_id;

-- :by_src_file_id
SELECT * FROM processes_registry WHERE src_file_id = ?;

-- :by_tgt_file_id
SELECT * FROM processes_registry WHERE tgt_file_id = ?;

-- :by_src_tunnel_id
SELECT * FROM processes_registry WHERE src_tunnel_id = ?;

--------------------------------------------------------------------------------
----------------------------------- INSERTS ------------------------------------
--------------------------------------------------------------------------------

-- :__insert
INSERT INTO processes_registry
  (
    server_id,
    process_id,
    entity_id,
    src_file_id,
    tgt_file_id,
    tgt_log_id,
    src_tunnel_id,
    inserted_at
  )
VALUES
  (?, ?, ?, ?, ?, ?, ?, ?)
RETURNING *;

--------------------------------------------------------------------------------
----------------------------------- DELETES ------------------------------------
--------------------------------------------------------------------------------

-- :delete
DELETE FROM processes_registry WHERE server_id = ? AND process_id = ?;

