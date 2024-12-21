CREATE TABLE processes_registry (
  server_id INTEGER,
  process_id INTEGER,
  entity_id INTEGER NOT NULL,
  tgt_log_id INTEGER,
  inserted_at TEXT NOT NULL,
  FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  PRIMARY KEY (server_id, process_id)
) STRICT, WITHOUT ROWID;

CREATE INDEX processes_registry_entity_id_idx ON processes_registry(entity_id);

CREATE INDEX processes_registry_tgt_log_id_idx ON processes_registry(tgt_log_id)
       WHERE (tgt_log_id IS NOT NULL);
