PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE __db_migrations (
  domain TEXT,
  version INTEGER,
  PRIMARY KEY (domain, version)
) STRICT;
INSERT INTO __db_migrations VALUES('game',240831163722);
INSERT INTO __db_migrations VALUES('game',240831163922);
INSERT INTO __db_migrations VALUES('game',240901133200);
INSERT INTO __db_migrations VALUES('game',241107222825);
INSERT INTO __db_migrations VALUES('game',241107222923);
INSERT INTO __db_migrations VALUES('game',241117084728);
CREATE TABLE __db_migrations_summary (
  domain TEXT,
  version INTEGER,
  PRIMARY KEY (domain, version)
) STRICT;
INSERT INTO __db_migrations_summary VALUES('game',241117084728);
CREATE TABLE entities ( id INTEGER PRIMARY KEY, type TEXT NOT NULL, inserted_at TEXT ) STRICT;
CREATE TABLE players ( id INTEGER PRIMARY KEY, external_id TEXT, inserted_at TEXT, FOREIGN KEY (id) REFERENCES entities(id) ON DELETE RESTRICT ON UPDATE RESTRICT ) STRICT;
CREATE TABLE servers ( id INTEGER PRIMARY KEY, entity_id INTEGER, inserted_at TEXT, FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE RESTRICT ON UPDATE RESTRICT ) STRICT;
CREATE TABLE network_connections ( nip TEXT PRIMARY KEY, server_id INTEGER NOT NULL, inserted_at TEXT NOT NULL, FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE RESTRICT ON UPDATE RESTRICT ) STRICT, WITHOUT ROWID;
CREATE TABLE tunnels ( id INTEGER PRIMARY KEY, source_nip TEXT NOT NULL, target_nip TEXT NOT NULL, access TEXT NOT NULL, status TEXT NOT NULL, inserted_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY (source_nip) REFERENCES network_connections(nip) ON DELETE RESTRICT ON UPDATE RESTRICT, FOREIGN KEY (target_nip) REFERENCES network_connections(nip) ON DELETE RESTRICT ON UPDATE RESTRICT ) STRICT;
CREATE TABLE tunnel_links ( tunnel_id INTEGER, idx INTEGER, nip TEXT NOT NULL, server_id INTEGER NOT NULL, inserted_at TEXT NOT NULL, FOREIGN KEY (tunnel_id) REFERENCES tunnels(id) ON DELETE RESTRICT ON UPDATE RESTRICT, FOREIGN KEY (nip) REFERENCES network_connections(nip) ON DELETE RESTRICT ON UPDATE RESTRICT, FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE RESTRICT ON UPDATE RESTRICT, PRIMARY KEY (tunnel_id, idx) ) STRICT;
CREATE TABLE connection_groups ( id INTEGER PRIMARY KEY, tunnel_id INTEGER NOT NULL, type TEXT NOT NULL, inserted_at TEXT NOT NULL, FOREIGN KEY (tunnel_id) REFERENCES tunnels(id) ON DELETE RESTRICT ON UPDATE RESTRICT ) STRICT;
CREATE TABLE connections ( id INTEGER PRIMARY KEY, nip TEXT NOT NULL, from_nip TEXT, to_nip TEXT, type TEXT NOT NULL, group_id INTEGER NOT NULL, tunnel_id INTEGER NOT NULL, inserted_at TEXT NOT NULL, FOREIGN KEY (group_id) REFERENCES connection_groups(id) ON DELETE RESTRICT ON UPDATE RESTRICT, FOREIGN KEY (tunnel_id) REFERENCES tunnels(id) ON DELETE RESTRICT ON UPDATE RESTRICT, FOREIGN KEY (nip) REFERENCES network_connections(nip) ON DELETE RESTRICT ON UPDATE RESTRICT, FOREIGN KEY (from_nip) REFERENCES network_connections(nip) ON DELETE RESTRICT ON UPDATE RESTRICT, FOREIGN KEY (to_nip) REFERENCES network_connections(nip) ON DELETE RESTRICT ON UPDATE RESTRICT ) STRICT;
CREATE UNIQUE INDEX players_external_id_idx ON players (external_id);
CREATE INDEX servers_entity_id_idx ON servers (entity_id);
CREATE INDEX network_connections_server_id_idx ON network_connections(server_id);
CREATE INDEX tunnels_source_nip_status_idx ON tunnels(source_nip);
CREATE INDEX tunnels_target_nip_status_idx ON tunnels(target_nip);
CREATE INDEX tunnel_links_nip_idx ON tunnel_links(nip);
CREATE INDEX connection_groups_tunnel_id_idx ON connection_groups(tunnel_id);
CREATE INDEX connections_group_id_idx ON connections(group_id);
CREATE INDEX connections_tunnel_id_idx ON connections(tunnel_id);
CREATE INDEX connections_nip_idx ON connections(nip);
COMMIT;
