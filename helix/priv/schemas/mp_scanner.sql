PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE __db_migrations (
  domain TEXT,
  version INTEGER,
  PRIMARY KEY (domain, version)
) STRICT;
INSERT INTO __db_migrations VALUES('scanner',251004115011);
CREATE TABLE __db_migrations_summary (
  domain TEXT,
  version INTEGER,
  PRIMARY KEY (domain, version)
) STRICT;
INSERT INTO __db_migrations_summary VALUES('scanner',251004115011);
CREATE TABLE instances ( id INTEGER PRIMARY KEY, entity_id INTEGER NOT NULL, server_id INTEGER NOT NULL, type TEXT NOT NULL, tunnel_id INTEGER, target_params TEXT, inserted_at TEXT NOT NULL, updated_at TEXT NOT NULL ) STRICT;
CREATE TABLE tasks ( instance_id INTEGER PRIMARY KEY, run_id TEXT NOT NULL, entity_id INTEGER NOT NULL, server_id INTEGER NOT NULL, type TEXT NOT NULL, target_id INTEGER, scheduled_at TEXT NOT NULL, completion_date INTEGER NOT NULL, next_backoff INTEGER, failed_attempts INTEGER NOT NULL, FOREIGN KEY(instance_id) REFERENCES instances(id) ) STRICT;
CREATE TABLE archived_task_runs ( instance_id INTEGER PRIMARY KEY, run_id TEXT NOT NULL, entity_id INTEGER NOT NULL, server_id INTEGER NOT NULL, type TEXT NOT NULL, target_id INTEGER, scheduled_at TEXT NOT NULL, completed_at INTEGER NOT NULL, archived_at TEXT NOT NULL ) STRICT;
CREATE UNIQUE INDEX instances_entity_id_server_id_idx ON instances(entity_id, server_id, type);
CREATE UNIQUE INDEX tasks_entity_id_server_id_idx ON tasks(entity_id, server_id, type);
CREATE UNIQUE INDEX tasks_run_id ON tasks(run_id);
CREATE INDEX archived_task_runs_run_id ON archived_task_runs(run_id);
COMMIT;
