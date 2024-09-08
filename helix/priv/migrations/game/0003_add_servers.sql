CREATE TABLE servers (
  id INTEGER PRIMARY KEY,
  entity_id INTEGER,
  inserted_at TEXT,
  FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX servers_entity_id_idx ON servers (entity_id);
