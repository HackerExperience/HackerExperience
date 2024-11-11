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

## Resolving a route

Question: how do I know that NIP A has access to NIP B? And how do I know the _player_ has access?

Well, theoretically any NIPs within the _same_ network can access each other (in a non-cyclical manner). There's half of your answer: make sure they are all within the same network.

If they aren't, then you need a special kind of verification:

It is entirely possible to go from network A to network B, as long as the server making that change has both networks in their NetworkConnection (right?).

Actually implementing networks is something I won't be doing now, so we don't need to worry about that scenario. Whenever we do implement it, we'll need to add these verifications, but they are entirely doable from a technical perspective.

Anyways, for now just make sure they all belong to the same network.

How about knowing whether the _player_ has access?

As mentioned above, access is represented by a Tunnel. If there is a Tunnel between S and T, and this tunnel is open and with type SSH, then yes the player has access.

So if we were to create an implicit bounce going from S -> T -> Z, we simply:

- /server/S/login/Z using tunnel_id of (S->T)
- There exists a tunnel S->T so we can route via S->T->Z

How about VPNs in general?

Even though they will not be implemented right now, VPNs represent a bunch of servers the player can login to _if necessary_. This "past access" is represented via their {username, password} pair stored in the Hacked Database.

So a Player can create a VPN of N hops and use them all if:

- The servers are stored in the Hacked Database with {username, password, ip}.
- This information is correct at the moment the Tunnel is created.

If the two points above are valid, the player can use the full VPN. If any of the hops have reset their IP address or changed their passwords, the connection will fail and the player should be presented with an option to adjust their VPN route.

