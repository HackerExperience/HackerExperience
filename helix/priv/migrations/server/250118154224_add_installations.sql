CREATE TABLE installations (
  id INTEGER PRIMARY KEY,
  file_type TEXT NOT NULL,
  file_version INTEGER NOT NULL,
  -- `file_id` refers to the File who originated the Installation, but it's nullable since the File
  -- may have been deleted after the installation took place.
  file_id INTEGER,
  memory_usage INTEGER NOT NULL,
  inserted_at TEXT NOT NULL
) STRICT;

CREATE INDEX installations_file_id_idx ON installations(file_id) WHERE file_id IS NOT NULL;
