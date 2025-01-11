# Processes

I'm inclined to heavily copy old Helix implementation, since I liked the end-result and how easy it was to *declare* how a Process should behave. The main difference will be the lack of macros -- I'd rather keep everything dynamic for improved compile-time.

Naturally, given the drastically different data architecture, many adjuments need to be made.

We store a list of every process in the game at the ProcessRegistry (Universe). This table tells us which processes are in a server, which servers have processes in them, and which data relates to this process (e.g. src_file_id, tgt_log_id etc).

If, say, a connection gets deleted, we can immediately know every process that would be affected by it by querying the src_conn_id or tgt_conn_id columns.

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

Another interesting optimization to make is consider the possiblity of "scanner process" not altering the resources of other process. In other words, I'm proposing that "scanner processes" have an orthogonal set of resources. By following this pattern, when a scanner process is retargeted (which may be often) it won't impact other processes (scanner or not), and therefore we won't need to recalculate everything.

Finally, it's important to make sure we only update the target/processed resources if a process actually changes, otherwise we'll get a lot of unnecessary IO on each recalculation

====

Resources

We have 4 big "maps" representing resources:

1. Allocated
2. Objective (or Target)
3. Processed
4. Remaining

We need to store the first three. The fourth (Reamining) can be derived from (Objective - Processed).

Allocated means the current "rate" of resources that are processed every second. "Objective" means the total amount of resources that need to be processed for process completion. And "Processed" means how far along we've come so far -- i.e. how many resources were processed thus far.

These maps are stored within each process

====

Processable

Upon conclusion, 3 possible actions:

- delete - ex: LogEdit
- retarget (update objective and data; reset processed) - ex: Bruteforce
- recreate (delete old + create new one) ex: *Scanner
|_ PS: Scanner procs may be retargeted (instead of recreated); it depends on how its data is used, how we convey the information to the client etc. *Ideally* it should be retargeted instead of recreated, but it may be different enough to warrant a full recreate.
|__ PPS: I suggested "recreated" because we need to update the Registry...


Regardless of the action, we always have two immediate events:
- ProcessCompletedEvent{process}
- SignaledEvent{process, action[delete|retarget|recreate]}

SignaledEvent *must* be handled synchronously, in the same "loop" -- it allows for optimizations (avoid re-scheduling when possible) and requires a realloc (when it can't be optimized).

ProcessCompletedEvent can be processed sync or async (no requirements either way). HOWEVER, the events generated by it *must* run asynchronously, since they may have to call the source TOP, thus creating a deadlock if the source TOP is processing everything synchronously.

Alternatively, emit SignaledEvent with a `performed?:true|false` flag. If performed? is false, the handler calls TOP. If performed? is true, handler no-ops (event is there for archive/debugg/log purposes only)

TODO: What happens if, on retarget, there is no available target? Sit around and wake up every few minutes?

=====

Communicating TOP changes to the Client

Every time the TOP changes, we emit a TOPChanged event. This TOPChanged event implements the Publishable trigger, BUT it only needs to change something to the Client if whatever changed is noticeable by the Client.

For example, if the process has one "Bruteforce" process that had its allocation changed, *nothing* will change to the client, since it can't see the allocation (or end date) anyways.

This is a possible optimization. It is probably a good thing to implement eventually, but it doesn't make sense right now. For the time being, just publish the entire TOP every time it changes...

PS: I can use the TOPChanged event as "trigger" for tests, so instead of sleeping a few ms I just wait for the event to get emitted... this means less flaky and more robust tests.


====

Priority

I'm not yet sure how priority will be presented to the player, but from the backend perspective the most flexible way is to allow each process to receive an arbitarily high number of "shares", whereas other processes receive the smallest possible number of shares (one). This would allow processes to use 99% of the dynamic resources, for example.

However, it's important to notice that share distribution is done per entity acting within a server, otherwise one user could "steal" shares from other users.

To solve this, I propose the following logic (brainstorm):

1. Count number of unique entities with active processes within the server
2. Split the total resources by this number
3. Split the process shares for this entity with the total resources *for this entity*

This works but requires a second pass to use resources dedicated to an entity that were not used (say, entity has a single download/upload process; the CPU shares dedicated to it were not used)

Alternatively, to avoid this second pass, we could count the number of unique entities *per resource*. I think that's overkill for now. We do a second pass anyways due to process limits.
