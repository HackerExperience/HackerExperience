CREATE TABLE file_visibilities (
  server_id INTEGER,
  file_id INTEGER,
  inserted_at TEXT NOT NULL,
  PRIMARY KEY (server_id, file_id)
) STRICT, WITHOUT ROWID;
