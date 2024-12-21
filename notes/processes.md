# Processes

I'm inclined to heavily copy old Helix implementation, since I liked the end-result and how easy it was to *declare* how a Process should behave. The main difference will be the lack of macros -- I'd rather keep everything dynamic for improved compile-time.

Naturally, given the drastically different data architecture, many adjuments need to be made.

We store a list of every process in the game at the ProcessRegistry (Universe). This table tells us which processes are in a server, which servers have processes in them, and which data relates to this process (e.g. src_file_id, tgt_log_id etc).

If, say, a connection gets deleted, we can immediately know every process that would be affected by it by querying the src_conn_id or tgt_conn_id tables.

Note that, at least for now, I'm keeping the ProcessRegistry table in the Universe shard, but it could very well be its own shard (to not lock the Universe). However, I believe our write pattern will be very process-biased, that is, almost every time we write to the Universe shard we also have to write to the ProcessRegistry. If this proves to not be true, then it would be beneficial to move ProcessRegistry to its own shard (or even Redis).

Finally, each process itself is stored within each Server shared (`Process` schema). This table holds the process objectives, resources and data. It also holds the registry data, but not to be queried (i.e. this is not indexed).

===

Old Helix follows the Executable Resourceable Processable Viewable model. I'll follow it too.

Executable: resolves the creation parameters of the process
Processable: defines how the process reacts to signals
Resourceable: defines which resources the process will use and what's the objective/target
Viewable: renders the process for the client

This worked great, there's no reason not to follow it.

===

Each Server with active processes will have its own GenServer that is responsible for tracking when the next process will reach its objective.

Old helix simply has one timer for each process, but I'll start with a more heavy approach: 1 genserver and 1 timer per Server. I think that will bring more robustness in the long term, albeit being heavier.

Note that not *every* server needs this GenServer, only the ones with active process. I'm not sure about the "always on" processes (Scanners), since they effectively create active process into *every* server. In the future, we may benefit from a more lightweight implementation for Scanners (i.e. by not considering them "full-blown" processes but instead a "lighter process" that is scheduled differently?)

Anyway, it's premature to worry about this for now, but it's certainly possible to optimize so only 10-20% of every server needs to have a stateful genserver.

Every time a process is started, recalculated, retargeted, reprioritiezed etc etc the GenServer will need to recalculate (recalque!) the entire TOP (Table Of Processes) to find out the "next to be completed".

It may (or may not be) a good a idea to trigger the Executable call (*Process.execute) within the GenServer itself. Not sure. We'll see.
