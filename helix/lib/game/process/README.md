# Process Domain

## High-level view of a Process

A Process is initially defined by `Process.Definition`. Pick any Process as example (say, `Process.Log.Edit`).

We have a `new/2` callback that receives the `params` and `meta` and returns the `data`, which is persisted on disk.

We have a `get_process_type/2` callback, which also receives both `params` and `meta`, to return the process type (an atom that defines the process).

And we have many triggers, like Processable, Signalable, Resourceable, Executable and Viewable, which implement custom behaviors during the entire lifecycle of the process.

The moment in which any of these callbacks are called is distinct. The origin of the call is spread across all the Process domain, too, which makes this a hard-to-follow code. The goal of this documentation is to make it easier to understand the high-level architecture of Process.

### The lifecycle of a Process

Let's use the LogEditProcess as example here.

A Process is first started by an explicit in-game action, arriving in the backend in the form of an HTTP request.

The corresponding endpoint (`Endpoint.Log.Edit`) will call `Process.TOP.execute/5`, passing in the following information:

- process module (`LogEditProcess`)
- server in which the process is taking place
- entity which started the process
- process params (extracted from the request params)
- process meta (gathered from the request context)

With this information, TOP will call `Executable.execute/5`.

Executable is a trigger responsible for the creation of the process. Based on the input described above, it will collect and store all the information that the process may need during its lifetime, including after it's completed.

All this gathering happens at `Executable.get_registry_params/2`. This (internal) function is so important it's worth mentioning in the high-level docs, and will provide a lot of insights into understanding how a process is created.

This is the function that calls the `new/2` and `get_process_type/2` callbacks mentioned in the beginning of this file.

It will also call all custom callbacks a process may implement in its `Executable` definition. For example, in the case of `LogEditProcess`, we have the `target_log/5` callback: this is telling us which log that particular process will target.

When a callback is not defined (say, `target_connection/5`), we just assume the process does not need any custom behaviors around this entity and return a `nil`.

This information will make up the Registry. We'll talk about the Process Registry at a later time, but think of it as a look up table where we can quickly find out which processes are interacting with which elements of the game (logs, connections, files etc).

Still inside the `Executable.get_registry_params/2` function, we will now fetch data related to resources: minimum and maximum amount of resources the process should use while running, which resources should be allocate dynamically, and what is the target/goal/objective of resources, which when reached means that the process has completed.

All this resource-related information is handled by the Resourceable trigger. In the `LogEditProcess` you can see it defines a minimum amount of RAM that must be used (with different values depending on whether the process is paused or not), as well as CPU being the dynamic resource that should be allocated to the process.

The Resourceable module has an entrypoint on `get_resources/2`, called from the `resources/1` callback inside the main `Process.Definition`, which is in turned called by the `Executable.get_registry_params/2`.

Whew, that's a lot. And that's *just* to get the process created. In any case, with all this information, the `Executable` will then call `Svc.Process.create/4`, which has all information it needs to insert the Process (and the corresponding ProcessRegistry) rows.

The creation of a process alters our TOP (Table Of Processes).

You see, so far everything I've described is essentially stateless. The TOP, however, is stateful. The `Process.TOP` main purpose is to bring life (statefulness) to the Process domain.

We have one TOP (GenServer) per in-game server. The TOP's main purpose is to find out when the next process (within that server) will complete, trigger its completion logic and recurse until the TOP is empty again (i.e. all processes have completed).

There are two major sub-modules in the TOP that helps with this: the `TOP.Allocator` and the `TOP.Scheduler`.

The `TOP.Allocator` single purpose is allocating the server resources to the existing processes in the server. It takes into consideration the Resourceable information and the total available resources in the server. You'll find a high-level description of the allocation process inside it.

Once the processes in the server have gone through the allocation step, they can go through the `TOP.Scheduler`. The Scheduler will estimate the completion date of each process, find out which one will complete next and tell TOP, which can sleep until the "next-to-be-complete" process isn't finished yet.

The Scheduler will also make sure that the processes are updated in the DB when their allocation changes. In the event of resources overflow (pointed out by the Allocator), the Scheduler will also drop processes recursively until there is sufficient resources for the remaining processes in the server.

All of this allocation-and-then-scheduling logic happens inside the `TOP.do_run_schedule/5` function. This is yet another extremely important internal function that is worth pointing out.

There are a number of triggers that will cause TOP to recalculate (that is, re-run the scheduling process). You can find an exhaustive list in the description of the `TOP.scheduler_run_reason` type.

Remember when we added the `LogEditProcess` just now? Well, that will trigger the TOP recalculation, which will allocate server resources to the process (prior to this, the process existed in the database but without any resources allocated to it, since it hasn't gone through the TOP yet).

After recalculation, TOP will sleep for as many (mili)seconds it needs until the `LogEditProcess` is finished (that is, the objective resources, defined in the mandatory Resourceable callback, were reached).

When a process finishes, TOP wakes up and triggers the `:next_process_completed` message. It will confirm the process actually finished processing and send a SIGTERM signal to the process.

You see, just like in the Linux kernel, in HE you too can send signals to processes. You have SIGTERM for process completion, SIGSTOP/SIGCONT for pause/resume, SIG_RENICE for renicing (changing the process priority), as well as "custom" signals like `SIG_TGT_LOG_DESTROYED`, which tells the process its target log was destroyed, or `SIG_SRC_CONN_CLOSED`, which tells the process the originating connection has been closed.

With these signals, each process can customize the behavior of what should happen under regular (and special) conditions. Maybe the `LogEditProcess` should kill itself when the log it was trying to edit has been destroyed. Maybe the `ResetIPProcess` can't be paused, and therefore it would return a `:noop` for the `SIGSTOP` signal.

Signals are handled via the Signalable trigger. The TOP will deliver the corresponding signal to the process (in this example, SIGTERM), which may return one of the possible actions: delete or retarget. Retarget makes sense for scanner-like processes, that have an always-on behavior and start working on something else as soon as it reaches the target. Delete means the process just gets deleted.

You may be asking yourself when does the log actually gets edited. We are almost there. Now that the Signalable returned a `:delete` action for the SIGTERM signal, TOP will delete the process (alongside the corresponding ProcessRegistry) entry, and it will emit a `ProcessCompletedEvent`.

The `ProcessCompletedEvent` contains, in its struct, the process we just deleted from disk. This event will be handled by `Handlers.Process.TOP`, which will call `Processable.on_complete/1`.

Enters the Processable trigger. The Processable offers callbacks that will be executed when the process actually completes (or gets killed, paused, resumed etc). In our example, we will finally perform the log editing in the `Processable.on_complete/1` callback! We could implement any clean-ups in the `Processable.on_kill/1` callback, for instance (which is optional and not needed for most processes).
