-- NOTE: I'm defaulting to `WITHOUT ROWID`, but the following excerpt makes me a bit worried on
-- whether that's the correct approach. I believe most logs will be small in size, but some logs may
-- have arbitrary data (and likely to be larger than 200/400 bytes (for 4/8 KB pages)). Needs proper
-- benchmark after the data model has matured.
--
-- From https://www.sqlite.org/withoutrowid.html:
--
-- WITHOUT ROWID tables work best when individual rows are not too large. A good rule-of-thumb is
-- that the average size of a single row in a WITHOUT ROWID table should be less than about 1/20th
-- the size of a database page. That means that rows should not contain more than about 50 bytes
-- each for a 1KiB page size or about 200 bytes each for 4KiB page size. WITHOUT ROWID tables will
-- work (in the sense that they get the correct answer) for arbitrarily large rows - up to 2GB in
-- size - but traditional rowid tables tend to work faster for large row sizes. This is because
-- rowid tables are implemented as B*-Trees where all content is stored in the leaves of the tree,
-- whereas WITHOUT ROWID tables are implemented using ordinary B-Trees with content stored on both
-- leaves and intermediate nodes. Storing content in intermediate nodes causes each intermediate
-- node entry to take up more space on the page and thus reduces the fan-out, increasing the search
-- cost.

CREATE TABLE logs (
  id INTEGER,
  revision_id INTEGER,
  type TEXT NOT NULL,
  data TEXT NOT NULL,
  inserted_at TEXT NOT NULL,
  PRIMARY KEY (id, revision_id)
) STRICT, WITHOUT ROWID;
