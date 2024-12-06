--------------------------------------------------------------------------------
----------------------------------- INSERTS ------------------------------------
--------------------------------------------------------------------------------

-- :__insert
INSERT INTO network_connections
  (nip, server_id, inserted_at)
VALUES
  (?, ?, ?)
RETURNING *;

--------------------------------------------------------------------------------
----------------------------------- SELECTS ------------------------------------
--------------------------------------------------------------------------------

-- :by_nip
SELECT * FROM network_connections WHERE nip = ?;

-- :by_server_id
SELECT * FROM network_connections WHERE server_id = ?;
