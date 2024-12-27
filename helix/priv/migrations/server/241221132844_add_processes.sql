CREATE TABLE processes (
  id INTEGER PRIMARY KEY,
  entity_id INTEGER NOT NULL,
  type TEXT NOT NULL,
  data TEXT NOT NULL,
  registry TEXT NOT NULL,
  resources TEXT NOT NULL,
  inserted_at TEXT NOT NULL
) STRICT;
