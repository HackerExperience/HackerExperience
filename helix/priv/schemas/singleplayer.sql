PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE __db_migrations (
  domain TEXT,
  version INTEGER,
  PRIMARY KEY (domain, version)
) STRICT;
INSERT INTO __db_migrations VALUES('game',240831163722);
INSERT INTO __db_migrations VALUES('game',240831163922);
INSERT INTO __db_migrations VALUES('game',240901133200);
INSERT INTO __db_migrations VALUES('game',241107222825);
CREATE TABLE __db_migrations_summary (
  domain TEXT,
  version INTEGER,
  PRIMARY KEY (domain, version)
) STRICT;
INSERT INTO __db_migrations_summary VALUES('game',241107222825);
CREATE TABLE entities ( id INTEGER PRIMARY KEY, type TEXT NOT NULL, inserted_at TEXT ) STRICT;
CREATE TABLE players ( id INTEGER PRIMARY KEY, external_id TEXT, inserted_at TEXT, FOREIGN KEY (id) REFERENCES entities(id) ON DELETE RESTRICT ON UPDATE RESTRICT ) STRICT;
CREATE TABLE servers ( id INTEGER PRIMARY KEY, entity_id INTEGER, inserted_at TEXT, FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE RESTRICT ON UPDATE RESTRICT ) STRICT;
CREATE TABLE network_connections ( nip TEXT PRIMARY KEY, server_id INTEGER NOT NULL, inserted_at TEXT NOT NULL, FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE RESTRICT ON UPDATE RESTRICT ) STRICT, WITHOUT ROWID;
CREATE UNIQUE INDEX players_external_id_idx ON players (external_id);
CREATE INDEX servers_entity_id_idx ON servers (entity_id);
CREATE INDEX network_connections_server_id_idx ON network_connections(server_id);
COMMIT;
