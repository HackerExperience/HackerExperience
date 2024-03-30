# DB

#### Migration

Each shard has its own schema version. Every shard's schema should converge to
the latest schema defined in the code. That happens, but eventually.

There are two ways where shards' schemas are kept up-to-date:

First, when the application starts, we grab the DB of shard_id=1. If that shard's
schema version is not the latest, then we assume a recent migration was added and
start migrating all shards sequentially.

This migration process happens "live", in parallel, as the system is receiving
customer requests.

As such, it's possible that a request for shard_id=9999 comes in right after we
started the migration process, meaning that shard isn't migrated yet.

This is why we also check the shard version EVERY TIME a connection is opened. If
the shard is not up-to-date, we'll synchronously migrate that specific shard
BEFORE accepting queries.

If the above process is implemented correctly, we can guarantee that:

1) All shards are eventually migrated to the latest version;
2) Migration can happen "live" with no downtimes (at most a delay until the
   migration is completed);
3) Every query always runs against the latest schema defined in the code.
