--------------------------------------------------------------------------------
----------------------------------- INSERTS ------------------------------------
--------------------------------------------------------------------------------

-- :__insert
INSERT INTO processes
  (entity_id, type, data, registry, resources, inserted_at)
VALUES
  (?, ?, ?, ?, ?, ?)
RETURNING *;
