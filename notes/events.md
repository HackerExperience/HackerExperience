# Helix Events

Events are ephemeral, temporary. They should work most of the time, but if they don't, there is little value in retrying them.

Contraty to Jobs, which should be retried, specially because they depend on external factors (unlike events) which may cause downtime.

As such, it makes sense to keep events as simple as possible, 100% local, without interacting with other piece of software (say, Redis or
even SQLite). Power loss and hard-termination may cause events to break in the middle of processing, leaving the database in an invalid
state. For the most part, I'm accepting that risk.

Deploys and server restarts should implement graceful terminations: give time for ongoing events to finish and make sure new event stacks
are not initiated (i.e. stop receiving requests, disable workers etc, wait a few seconds and then shut down the application).

They should be very well logged and with good visibility, as well as proper tracing and backtrack information. Those will be invaluable to
debugging.