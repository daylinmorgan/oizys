## miniflux database migration -- 2026.10.18

```sh
sudo -u postgres reindexdb -d miniflux
```
```sh
sudo -u postgres psql -d miniflux
```
```sql
ALTER DATABASE miniflux REFRESH COLLATION VERSION;
```
Returned:
```txt
changing version from 2.42 to 2.44
ALTER DATABASE
```
