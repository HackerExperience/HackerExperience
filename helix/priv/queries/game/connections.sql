--------------------------------------------------------------------------------
----------------------------------- INSERTS ------------------------------------
--------------------------------------------------------------------------------

-- :__insert
INSERT INTO connections
  (nip, from_nip, to_nip, type, group_id, tunnel_id, inserted_at)
VALUES
  (?, ?, ?, ?, ?, ?, ?)
RETURNING *;
