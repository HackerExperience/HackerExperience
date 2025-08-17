CREATE TABLE files (
  -- NOTE: `AUTOINCREMENT` is used on purpose because we can't reuse old ROWIDs (might conflict with
  -- FileVisibility entries).
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,
  name TEXT NOT NULL,
  -- NOTE: A version of `23` means "2.3"
  version INTEGER NOT NULL,
  size INTEGER NOT NULL,
  path TEXT NOT NULL,
  inserted_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
) STRICT;

CREATE UNIQUE INDEX files_path_name ON files(path, name, type);
