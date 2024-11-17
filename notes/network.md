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

## Connection Groups

What is a connection _group_ and how does it differ from a "connection"?

As mentioned above, a connection represents an _action_. If S has an SSH connection on T, that's an action, and that's represented by a connection (and also a tunnel).

Imagine that we have an SSH connection in a classic S -> AP -> EN -> T route. What happens when attacker A runs nmap on S? And T? And AP/EN? What happens when they exploit it?

Here's a breakdown:

A runs nmap on T. It will eventually see that there's a *SSH* connection coming from EN.

Then, A logs into EN and looks for nmap. A already knows there's an outgoing SSH connection _from_ EN _to_ T, so that's immediatelly visible.

Over time, A will eventually find a "Proxy-SSH" connection from AP to EN. It indicates that EN is only a puppet, and someone (maybe AP, maybe someone else) is doing things on behalf of EN.

Similarly, once A runs nmap on AP, it will find a "Proxy-SSH" connection from S to AP.

Then, once A runs nmap on S, it will find a "Proxy-SSH" connection from *localhost* to AP.

What happens when A exploits the connection in S? And in AP? EN? T?

That's out of scope for now, but the current consensus is that:

T -> Gives SSH access to EN
EN -> Gives SSH access to AP
AP -> Gives SSH access to S
S -> Gives SSH access to T

Listen to my audios for more context. This is not set in stone, but I like it.

Anyways, back to groups and "individual" connections. Why do groups exist?

Well, using this same example, when an S -> AP -> EN -> T tunnel is created, this creates a connection _group_ of type _ssh_ **in** the tunnel.

This means the tunnel has an SSH connection in it. It could also have FTP connections, DDoS etc.

However, the individual connections between S and AP may be different than EN to T.

EN -> T is an SSH connection in the SSH group
S -> AP and AP -> EN are a proxy connection in the SSH group

Let's break this down into actual entries.

S -> AP

nip: S
from_nip: null
to_nip: AP
type: Proxy
group_id: ssh

AP -> EN

nip: AP
from_nip: S
to_nip: EN
type: Proxy
group_id: ssh

EN -> T

nip: EN
from_nip: AP
to_nip: null
type: Proxy
group_id: ssh

nip: EN
from_nip: null
to_nip: T
type: SSH
group_id: ssh

Okay, looks good. What happens when somebody (with zero context) runs nmap in AP? They will find:

S:

1 "Proxy" connection from localhost to AP

AP:

1 "Proxy" connection from S to localhost
2 "Proxy" connection from localhost to EN

EN:

1 "Proxy" connection from AP to localhost
2 "SSH" connection from localhost to EN

T:

1. "SSH" connection from EN to localhost

Keep in mind that the "target" (to_nip) connection is hidden by default, unless the player has HDB access to them. One acceptable exception is if they have access to the S, in which case they are rewarded the T because they found the very origin of the attack.

So, to summarize:

Why groups? So that when the player e.g. logs out of an existing SSH connection, or a process completes the FTP transfer, all connections within that group die instantly (cascading, for example).

Why individual connections? So that when a player runs nmap in a particular server, or exploits a particular connection, we know precisely what should happen, who comes before, who comes after etc.
