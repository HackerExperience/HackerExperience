-- TODO: Comments at the middle of a SQL migration query breaks DBLite
-- `external_id` is the same as `lobby.users.external_id`
CREATE TABLE players (
  id INTEGER PRIMARY KEY,
  external_id TEXT,
  inserted_at TEXT
) STRICT;

CREATE UNIQUE INDEX players_external_id_idx ON players (external_id);
