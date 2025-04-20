PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE __db_migrations (
  domain TEXT,
  version INTEGER,
  PRIMARY KEY (domain, version)
) STRICT;
INSERT INTO __db_migrations VALUES('server',241020084800);
INSERT INTO __db_migrations VALUES('server',241221132844);
INSERT INTO __db_migrations VALUES('server',241229175238);
INSERT INTO __db_migrations VALUES('server',250118153531);
INSERT INTO __db_migrations VALUES('server',250118154224);
CREATE TABLE __db_migrations_summary (
  domain TEXT,
  version INTEGER,
  PRIMARY KEY (domain, version)
) STRICT;
INSERT INTO __db_migrations_summary VALUES('server',250118154224);
CREATE TABLE logs ( id INTEGER NOT NULL, revision_id INTEGER NOT NULL, type TEXT NOT NULL, direction TEXT NOT NULL, data TEXT NOT NULL, inserted_at TEXT NOT NULL, deleted_at TEXT NULL, deleted_by TEXT NULL, UNIQUE (id, revision_id) ) STRICT;
CREATE TABLE processes ( id INTEGER PRIMARY KEY, entity_id INTEGER NOT NULL, type TEXT NOT NULL, data TEXT NOT NULL, registry TEXT NOT NULL, status TEXT NOT NULL, resources TEXT NOT NULL, priority INTEGER NOT NULL, inserted_at TEXT NOT NULL, last_checkpoint_ts INTEGER, estimated_completion_ts INTEGER ) STRICT;
CREATE TABLE meta ( id INTEGER PRIMARY KEY, entity_id INTEGER NOT NULL, resources TEXT NOT NULL ) STRICT;
CREATE TABLE files ( id INTEGER PRIMARY KEY, type TEXT NOT NULL, name TEXT NOT NULL, version INTEGER NOT NULL, size INTEGER NOT NULL, path TEXT NOT NULL, inserted_at TEXT NOT NULL, updated_at TEXT NOT NULL ) STRICT;
CREATE TABLE installations ( id INTEGER PRIMARY KEY, file_type TEXT NOT NULL, file_version INTEGER NOT NULL, file_id INTEGER, memory_usage INTEGER NOT NULL, inserted_at TEXT NOT NULL ) STRICT;
CREATE UNIQUE INDEX files_path_name ON files(path, name, type);
CREATE INDEX installations_file_id_idx ON installations(file_id) WHERE file_id IS NOT NULL;
COMMIT;
