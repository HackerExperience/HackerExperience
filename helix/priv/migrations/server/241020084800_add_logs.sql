-- NOTE: I'm using a UNIQUE index instead of having (id, revision_id) as PRIMARY KEY. The reason
-- being that composite PKs 1) require WITHOUT ROWID tables and 2) can't AUTOINCREMENT.
CREATE TABLE logs (
  id INTEGER PRIMARY KEY,
  revision_id INTEGER NOT NULL,
  type TEXT NOT NULL,
  data TEXT NOT NULL,
  inserted_at TEXT NOT NULL,
  UNIQUE (id, revision_id)
) STRICT;
