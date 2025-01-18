PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE __db_migrations (
  domain TEXT,
  version INTEGER,
  PRIMARY KEY (domain, version)
) STRICT;
INSERT INTO __db_migrations VALUES('player',241020094500);
INSERT INTO __db_migrations VALUES('player',250118202152);
CREATE TABLE __db_migrations_summary (
  domain TEXT,
  version INTEGER,
  PRIMARY KEY (domain, version)
) STRICT;
INSERT INTO __db_migrations_summary VALUES('player',250118202152);
CREATE TABLE log_visibilities ( server_id INTEGER, log_id INTEGER, revision_id INTEGER, inserted_at TEXT NOT NULL, PRIMARY KEY (server_id, log_id, revision_id) ) STRICT, WITHOUT ROWID;
CREATE TABLE file_visibilities( server_id INTEGER, file_id INTEGER, inserted_at TEXT NOT NULL, PRIMARY KEY (server_id, file_id) ) STRICT, WITHOUT ROWID;
COMMIT;
