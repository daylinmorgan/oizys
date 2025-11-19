# bluesky pds

## setup

modified their docker compose file
and manually generated the pds.env file
by recreating their installer scripts steps

---

I don't love that I deployed this at `bsky.dayl.in` rather than the more general `pds.dayl.in` or `atproto.dayl.in`.
Based on a quick search it seems just updating the hostname is likely to fail.
Meaning the best option would probably be to spin up a competing `pds` and migrate my account.

Either way I'll sit on this for now and maybe the tooling will get better down the line.
