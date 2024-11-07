# Network

Tunnels, Connections, VPNs: they are all part of the Network domain. Their most fundamental purpose is to enable connectivity between Servers.

We only need 4 tables to represent pretty much everything we'd want to know regarding Tunnels and Connections:

U_tunnels
U_tunnel_links
U_connections
U_connection_groups

For more details, check the DB diagram (not yet a part of this repo, I'm afraid).

A few remarks:

- Tunnel represents *access*.
  - We use the Tunnel to know whether and how much permission the user has in a remote server.
- Connection represents an *action*.
- Multiple connections may go through a single tunnel.
- A tunnel has multiple hops. Key hops of a tunnel are: Source (S), Access Point (AP), Exit Node (EN) and Target (T)
