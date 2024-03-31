PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE __db_migrations (
  domain text,
  version integer,
  inserted_at TEXT NOT NULL,
  PRIMARY KEY (domain, version)
) STRICT;
INSERT INTO __db_migrations VALUES('lobby',1,'2024-03-31 14:24:37');
CREATE TABLE __db_migrations_summary (
  domain text,
  version integer,
  inserted_at TEXT NOT NULL,
  PRIMARY KEY (domain, version)
) STRICT;
INSERT INTO __db_migrations_summary VALUES('lobby',1,'2024-03-31 14:24:37');
CREATE TABLE users (  id INTEGER PRIMARY KEY,  external_id TEXT,  username TEXT,  email TEXT,  password TEXT,  inserted_at TEXT) STRICT;
CREATE UNIQUE INDEX users_external_id_idx ON users (external_id);
CREATE UNIQUE INDEX users_email_idx ON users (email);
CREATE UNIQUE INDEX users_username_idx ON users (username);
COMMIT;
