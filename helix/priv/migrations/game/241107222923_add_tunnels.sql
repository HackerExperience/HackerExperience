CREATE TABLE tunnels (
  id INTEGER PRIMARY KEY,
  source_nip TEXT NOT NULL,
  target_nip TEXT NOT NULL,
  access TEXT NOT NULL,
  -- TODO: Maybe `status` could be an integer?
  status TEXT NOT NULL,
  inserted_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (source_nip) REFERENCES network_connections(nip) ON DELETE RESTRICT ON UPDATE RESTRICT,
  FOREIGN KEY (target_nip) REFERENCES network_connections(nip) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

-- NOTE: An index on (*_nip, status) may make more sense than (*_nip). Confirm, benchmark, change.
CREATE INDEX tunnels_source_nip_status_idx ON tunnels(source_nip);
CREATE INDEX tunnels_target_nip_status_idx ON tunnels(target_nip);

CREATE TABLE tunnel_links (
  tunnel_id INTEGER,
  idx INTEGER,
  nip TEXT NOT NULL,
  inserted_at TEXT NOT NULL,
  FOREIGN KEY (tunnel_id) REFERENCES tunnels(id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  FOREIGN KEY (nip) REFERENCES network_connections(nip) ON DELETE RESTRICT ON UPDATE RESTRICT,
  PRIMARY KEY (tunnel_id, idx)
) STRICT;

CREATE INDEX tunnel_links_nip_idx ON tunnel_links(nip);
