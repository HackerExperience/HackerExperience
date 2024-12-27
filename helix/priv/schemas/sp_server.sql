PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE __db_migrations (
  domain TEXT,
  version INTEGER,
  PRIMARY KEY (domain, version)
) STRICT;
INSERT INTO __db_migrations VALUES('server',241020084800);
INSERT INTO __db_migrations VALUES('server',241221132844);
CREATE TABLE __db_migrations_summary (
  domain TEXT,
  version INTEGER,
  PRIMARY KEY (domain, version)
) STRICT;
INSERT INTO __db_migrations_summary VALUES('server',241221132844);
CREATE TABLE logs ( id INTEGER, revision_id INTEGER NOT NULL, type TEXT NOT NULL, data TEXT NOT NULL, inserted_at TEXT NOT NULL, UNIQUE (id, revision_id) ) STRICT;
CREATE TABLE processes ( id INTEGER PRIMARY KEY, entity_id INTEGER NOT NULL, type TEXT NOT NULL, data TEXT NOT NULL, registry TEXT NOT NULL, resources TEXT NOT NULL, inserted_at TEXT NOT NULL ) STRICT;
COMMIT;
