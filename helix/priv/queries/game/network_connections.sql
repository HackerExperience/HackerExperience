--------------------------------------------------------------------------------
----------------------------------- INSERTS ------------------------------------
--------------------------------------------------------------------------------

-- :__insert
INSERT INTO network_connections
  (nip, server_id, inserted_at)
VALUES
  (?, ?, ?)
RETURNING *;


