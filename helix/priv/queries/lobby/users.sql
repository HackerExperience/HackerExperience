--------------------------------------------------------------------------------
----------------------------------- INSERTS ------------------------------------
--------------------------------------------------------------------------------

-- :__insert
INSERT INTO users
  (external_id, username, email, password, inserted_at)
VALUES
  (?, ?, ?, ?, ?)
RETURNING *;

--------------------------------------------------------------------------------
----------------------------------- SELECTS ------------------------------------
--------------------------------------------------------------------------------

-- -- :get_by_external_id
-- select * from accounts where external_id = ?;

-- :get_by_username
SELECT * FROM users WHERE username = ? LIMIT 1;

-- :get_by_email
SELECT * FROM users WHERE email = ? LIMIT 1;

-- -- :count_by_username
-- select `count(*)` from accounts where username = ? limit 1;

-- -- :count_by_email
-- select `count(*)` from accounts where email = ? limit 1;

-- -- :last_inserted_id
-- select id from accounts order by id desc limit 1;
