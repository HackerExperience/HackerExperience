CREATE TABLE files (
  id INTEGER PRIMARY KEY,
  type TEXT NOT NULL,
  -- NOTE: A version of `23` means "2.3"
  version INTEGER NOT NULL,
  size INTEGER NOT NULL,
  path TEXT NOT NULL,
  inserted_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
) STRICT;
