# Forgejo

This was part of a docker compose before I it moved here.
When I switched to podman I needed to update the permissions for `/home/git/.ssh` to be owned by the `git` user.
For some reason they were owned by `daylin`.
