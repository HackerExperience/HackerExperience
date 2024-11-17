CREATE TABLE connection_groups (
  id INTEGER PRIMARY KEY,
  tunnel_id INTEGER NOT NULL,
  group_type TEXT NOT NULL,
  inserted_at TEXT NOT NULL,
  FOREIGN KEY (tunnel_id) REFERENCES tunnels(id) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX connection_groups_tunnel_id_idx ON connection_groups(tunnel_id);

CREATE TABLE connections (
  id INTEGER PRIMARY KEY,
  nip TEXT NOT NULL,
  from_nip TEXT,
  to_nip TEXT,
  connection_type TEXT NOT NULL,
  group_id INTEGER NOT NULL,
  tunnel_id INTEGER NOT NULL,
  inserted_at TEXT NOT NULL,
  -- NOTE: Most likely, we want ON DELETE CASCADE but I'll keep restrict and, when the time comes,
  -- I'll let myself decide if CASCADE makes sense or if I want to be explicit about it.
  FOREIGN KEY (group_id) REFERENCES connection_groups(id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  FOREIGN KEY (tunnel_id) REFERENCES tunnels(id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  FOREIGN KEY (nip) REFERENCES network_connections(nip) ON DELETE RESTRICT ON UPDATE RESTRICT,
  FOREIGN KEY (from_nip) REFERENCES network_connections(nip) ON DELETE RESTRICT ON UPDATE RESTRICT,
  FOREIGN KEY (to_nip) REFERENCES network_connections(nip) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

CREATE INDEX connections_group_id_idx ON connections(group_id);
CREATE INDEX connections_tunnel_id_idx ON connections(tunnel_id);
CREATE INDEX connections_nip_idx ON connections(nip);
