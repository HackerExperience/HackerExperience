CREATE TABLE external_ids (
  external_id TEXT PRIMARY KEY,
  object_id INTEGER NOT NULL,
  object_type TEXT NOT NULL,
  domain_id INTEGER,
  subdomain_id INTEGER,
  inserted_at TEXT NOT NULL
) STRICT, WITHOUT ROWID;

CREATE UNIQUE INDEX external_ids_unique_object_identifier_idx
ON external_ids(object_id, object_type, domain_id, subdomain_id);
