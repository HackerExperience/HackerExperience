--------------------------------------------------------------------------------
----------------------------------- SELECTS ------------------------------------
--------------------------------------------------------------------------------

-- :by_id
SELECT * FROM instances WHERE id = ?;

-- :by_entity_server
SELECT * FROM instances WHERE entity_id = ? AND server_id = ?;

-- :by_entity_server_type
SELECT * FROM instances WHERE entity_id = ? AND server_id = ? AND type = ?;

--------------------------------------------------------------------------------
----------------------------------- INSERTS ------------------------------------
--------------------------------------------------------------------------------

-- :__insert
INSERT INTO instances (
  entity_id, server_id, type, tunnel_id, target_params, inserted_at, updated_at
  )
VALUES
  (?, ?, ?, ?, ?, ?, ?)
RETURNING *;

--------------------------------------------------------------------------------
----------------------------------- DELETES ------------------------------------
--------------------------------------------------------------------------------

-- :delete_by_entity_server
DELETE FROM instances WHERE entity_id = ? AND server_id = ?;

