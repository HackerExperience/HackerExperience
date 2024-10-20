CREATE TABLE log_visibilities (
  server_id INTEGER,
  log_id INTEGER,
  revision_id INTEGER,
  inserted_at TEXT NOT NULL,
  PRIMARY KEY (server_id, log_id, revision_id)
) STRICT, WITHOUT ROWID;
