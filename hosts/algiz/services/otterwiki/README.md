# wiki

a private wiki powered by [otterwiki](https://otterwiki.com)


## initial setup


For some reason using the slim variant was causing errors since the repo wasn't writable by uid=33.
To resolve I pre-generated the directory for the git repository

```sh
mkdir -p app-data/repository
sudo chown 33 -R app-data
```

---

This existed as a standalone directory previously.
The database file (`app-data/`) was moved to /opt/otterwiki/app-data.
