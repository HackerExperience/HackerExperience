--------------------------------------------------------------------------------
----------------------------------- INSERTS ------------------------------------
--------------------------------------------------------------------------------

-- :__insert
INSERT INTO tunnels
  (source_nip, target_nip, access, status, inserted_at, updated_at)
VALUES
  (?, ?, ?, ?, ?, ?)
RETURNING *;
