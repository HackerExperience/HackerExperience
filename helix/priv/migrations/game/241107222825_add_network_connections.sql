CREATE TABLE network_connections (
  nip TEXT PRIMARY KEY,
  server_id INTEGER NOT NULL,
  inserted_at TEXT NOT NULL,
  FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT, WITHOUT ROWID;

CREATE INDEX network_connections_server_id_idx ON network_connections(server_id);
