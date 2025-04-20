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


-- :by_server_ordered
SELECT log_id, MAX(revision_id) AS latest_revision_id
FROM log_visibilities
WHERE server_id = ?
GROUP BY log_id
ORDER BY log_id DESC
LIMIT 50;

-- :__fetch
SELECT * FROM log_visibilities WHERE server_id = ? AND log_id = ? AND revision_id = ?;


