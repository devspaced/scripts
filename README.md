# Scripts

## Dev server scripts
Run
```sh
chmod +x dev_server.sh
./dev_server
```
# Dev Server Setup — Ubuntu 26.04 LTS (Resolute Raccoon)

This documents the local services installed via `setup-dev-server.sh` and how to connect to each.

## Services & Ports

| Service     | Port(s)         | Default Credentials                  |
|-------------|------------------|----------------------------------------|
| PostgreSQL  | 5432             | user: `postgres`, no password by default |
| MongoDB     | 27017            | no auth by default                    |
| Redis       | 6379             | no password by default                |
| Neo4j       | 7474 (HTTP), 7687 (Bolt) | user: `neo4j`, password: `neo4j` (forced change on first login) |
| Qdrant      | 6333 (HTTP), 6334 (gRPC) | no auth by default (runs as a Docker container) |
| Docker      | —                | n/a (local daemon)                    |
| kubectl     | —                | depends on cluster config             |

Check all services are running:
```bash
sudo systemctl status postgresql mongod redis-server neo4j
docker ps   # check qdrant container is up
```

---

## PostgreSQL

Set a password (none is set by default):
```bash
sudo -u postgres psql
postgres=# \password postgres
postgres=# CREATE DATABASE mydb;
postgres=# \q
```

**Connect:**
```bash
psql postgresql://postgres:<password>@localhost:5432/mydb
```

**Connection string:**
```
postgresql://postgres:<password>@localhost:5432/mydb
```

For remote access, edit:
- `/etc/postgresql/18/main/postgresql.conf` → `listen_addresses = '*'`
- `/etc/postgresql/18/main/pg_hba.conf` → allow the connecting IP range

---

## MongoDB

No auth is enabled by default. To enable it:
```bash
mongosh
use admin
db.createUser({ user: "admin", pwd: "yourpassword", roles: ["root"] })
exit
```
Then edit `/etc/mongod.conf`:
```yaml
security:
  authorization: enabled
```
```bash
sudo systemctl restart mongod
```

**Connect:**
```bash
mongosh "mongodb://admin:yourpassword@localhost:27017"
```

**Connection string:**
```
mongodb://admin:yourpassword@localhost:27017
```

---

## Redis

No password by default, bound to `localhost` only.

**Connect:**
```bash
redis-cli
PING   # expect PONG
```

To set a password, edit `/etc/redis/redis.conf`:
```
requirepass yourpassword
```
```bash
sudo systemctl restart redis-server
redis-cli -a yourpassword
```

**Connection string:**
```
redis://localhost:6379
```

---

## Neo4j

Default login: `neo4j` / `neo4j` — forces a password change on first connect.

**Connect (CLI):**
```bash
cypher-shell -u neo4j -p neo4j
```

**Connect (browser UI):**
```
http://localhost:7474
```

**Bolt connection string** (for drivers/apps):
```
bolt://neo4j:<newpassword>@localhost:7687
```

---

## Qdrant (vector database)

Runs as a Docker container, not a systemd service. Storage persists to `/opt/qdrant/storage` on the host.

**Check it's running:**
```bash
docker ps                # should show a container named "qdrant"
docker logs qdrant       # view logs
```

**Web dashboard:**
```
http://localhost:6333/dashboard
```

**REST API base URL:**
```
http://localhost:6333
```

**gRPC port:** `6334`

No authentication is enabled by default — fine for local dev, but add an API key before exposing this beyond `localhost`:
```bash
docker run -d --name qdrant --restart unless-stopped \
  -p 6333:6333 -p 6334:6334 \
  -v /opt/qdrant/storage:/qdrant/storage \
  -e QDRANT__SERVICE__API_KEY=yourkey \
  qdrant/qdrant
```
(Remove and re-run the container with this env var added — Qdrant doesn't hot-reload config.)

**Client libraries:** `qdrant-client` (Python), `@qdrant/js-client-rest` (JS/TS), or the `qdrant-client` crate (Rust). DataGrip has no native Qdrant driver since it isn't a SQL database — use the dashboard or a client library instead.

---

## Docker

```bash
docker --version
docker run hello-world
```
If you get a permissions error, log out/in (or `newgrp docker`) so your group membership takes effect.

## kubectl

```bash
kubectl version --client
```
Requires a `~/.kube/config` pointing at a cluster to do anything beyond version check.

## Go / Rust

```bash
go version
rustc --version
```

---

## Notes

- All services above are configured for **local development** — none are hardened for production or remote exposure out of the box.
- If connecting from another machine (not `localhost`), you'll need to both bind the service to a non-loopback address and open the relevant port in the firewall:
  ```bash
  sudo ufw allow <port>
  ```
- MongoDB and PostgreSQL apt repos are pinned to the `noble` (24.04) or `resolute` (26.04) codename respectively — see `setup-dev-server.sh` comments if repos need updating later.
