# How do you know what's the "latest" log that should be shown in any given server?

/\ Well, what if you don't?

You really only gets to "know" a log via the LogScanner process. This process will recursively grab
a random log entry from the "log pool" (i.e. every available log in the server). When it grabs a
log entry, it makes sure that this particular entry is being worked in the latest revision.

Personally, I think it's simpler/better to have one universal log identifier (instead of (log_id, rev_id))

However, we still need a way to map previous/next revisions.

How about:

S_logs
[
id
log_type
log_data
parent_id
]

by using this `parent_id` field, we can iterate over every revision until `parent_id=nil`

# How about "hiding" logs? How does that work?

Hiding simply adds a new revision on top (with maybe log_type=hidden, and possibly the hidden version in the data so it can be used by the LogScanner)

# What happens if I (or someone else) hides a log that I previously had visibility?

The visibility is "locked". If I found a log with rev1, and somebody changes it creating rev2, I will still see rev1.

# What if server changes IP address? How to not leak server identification via external log_id?

"Re-key" the external IDs for every log from that particular server. Not trivial but technically doable.

# Should we have a revision table separate for each log? Does each revision creates its own log id?

Answered in first question. Each revision is its own log, makes for easier mapping. We rarely have to go through revisions, and when we do, we can iterate via `parent_id`.

# When DO we have to go through revisions?

When adding a new revision we need to add the `parent_id`. But when do we query it?

When LogScanner picks a log that I already have access to but it has multiple revisions so I can "find" the previous version.

# Let's say you have visibility over multiple revisions from the same log entry. How do we show that in the UI?

If we want to show a single entry per log (regardless of revisions), it gets a bit hard to do if each log has its own ID...

It may also make sense to allow the player to see previous revisions from the log (otherwise data from the first revisioun found is lost unless the player manually wrote it down somewhere / memorized it)

But in order to do that, we need to rethink IDs. We'd need potentially two external IDs for logs:

revision_id :: identifies (log_id, rev_id)
log_id :: identifies (log_id)

We can then group log entries by `log_id`, and if multiple `revision_id`s are found we can show them together. Note that then we need to find a way to tell the Client which revision came before which one

Do we display revision_date? I think no. Only the log creation_date, which cannot be changed.

# Re-thinking IDs

Based on the above question (how to display in the UI), we kinda need something like (log_id, rev_id)

Let's imagine the following log stack:

1: [1.2.3.4] logged in
2: [] logged in
3: <<hidden>>

Imagine this particular log has `log_id=X`

`X` identifies the log stack, and `1/2/3` identifies the revision inside it.

We could send something like this to the UI:

{
  logs: [

    {
      "id": "external(1)",
      "revisions": [
        {
          "id": "external(1, 3)",
          "data": {}
        }
      ]
    }
  ]
}

(PS: format above may be changed for easier parsing on Client side)

Notice we need two external IDs. We can't leak the revision int (otherwise the player will know how many revisions there are). Similarly, we can't leak the int log id, since it will tell how mnay logs there are.

I don't like having a minimum of two external IDs per log entry but I can't think of an alternative solution without leaking internal data.

The above JSON format will have sufficient information for anything the UI needs to do with the data, be it grouping, showing a "history" of revisions etc.

Based on this rethinking of the IDs, we need to change the proposed model to:

S_logs
[
id
rev_id
log_type
log_data
]

Using the same log stack above as example, we'd have:

id: 1
rev_id: 1/2/3

Does this change any of the assumptions/answers in previous questions?

LogScanner will pick a random log_id, and then it can issue another query where it gets every revision for that particular log.

If the player has visibility on (log_id, rev_id) (any revisions from that log), then LogScanner will pick log with (log_id, last_rev_id - 1).
Else, LogScanner will pick (log_id, max(rev_id))

# How do we guarantee order?

Default order is by log creation_date. Since IDs are sequential, and new revisions don't alter the log ID, we can reliably use `order by id asc/desc`.

# Hide vs Encrypt

One can think of each log entry as always being hidden by default, which kinda defeats the original purpose of the LogHider. However, hiding is still desirable since it's supposed to increase the difficulty of LogScanning that particular log.

Now imagine a hidden log entry was recovered. How is it supposed to show up in the UI?

If hiding a log entry generates a `log_type=hidden` revision, then LogScanning it means you have access to _this_ revision. Theoretically, in the UI we don't have any data to show other than "<<HIDDEN LOG>>".

(The alternative is, upon LogScanner completion, once the system realizes it's a hidden log it automatically 1) increases the time to scan it and 2) recovers to the revision prior to hiding).

Could it be more immersive to add log encryption instead? Instead of showing <<HIDDEN LOG>>, we show garbage/encrypted-like text in the UI, telling the user there _is_ a log but it's encrypted.

That's worth considering in the future. It's a problem for whenever I add the hide/encrypt feature, but (and the most important thing at this stage) I don't see either of them affecting the data model being proposed here.

# localhost logged in : should we show this on user login?

There are valid questions here. For now, let's skip this and revisit at a later time.
