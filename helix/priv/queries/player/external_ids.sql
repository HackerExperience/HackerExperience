--------------------------------------------------------------------------------
----------------------------------- SELECTS ------------------------------------
--------------------------------------------------------------------------------

-- :__fetch
SELECT * FROM external_ids WHERE external_id = ?;

-- :by_internal_id_nodomain
SELECT * FROM external_ids WHERE object_id = ? AND object_type = ? LIMIT 1;

-- :by_internal_id_nosubdomain
SELECT * FROM external_ids WHERE object_id = ? AND object_type = ? AND domain_id = ? LIMIT 1;

-- :by_internal_id_full
SELECT *
FROM external_ids
WHERE object_id = ? AND object_type = ? AND domain_id = ? AND subdomain_id = ? LIMIT 1;

--------------------------------------------------------------------------------
----------------------------------- INSERTS ------------------------------------
--------------------------------------------------------------------------------

-- :__insert
INSERT INTO external_ids
  (external_id, object_id, object_type, domain_id, subdomain_id, inserted_at)
VALUES
  (?, ?, ?, ?, ?, ?)
RETURNING *;

