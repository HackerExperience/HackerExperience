CREATE TABLE server_mappings (
  server_id INTEGER PRIMARY KEY,
  entity_id INTEGER,
  inserted_at TEXT,
  FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX server_mappings_entity_id_idx ON server_mappings (entity_id);
