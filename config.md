# Database Server Config Reference

Server: `192.168.0.2` — Ubuntu 26.04 LTS (Resolute Raccoon)
Purpose: config changes made to expose each DB to DataGrip (running on laptop, not on the server).

---

## PostgreSQL

**Config files edited:**
- `/etc/postgresql/18/main/postgresql.conf`
  ```
  listen_addresses = '*'
  ```
- `/etc/postgresql/18/main/pg_hba.conf`
  ```
  host    all             all             0.0.0.0/0               scram-sha-256
  ```

**Commands run:**
```bash
sudo systemctl restart postgresql
sudo ufw allow 5432
```

**Auth:** user `postgres`, password set via `\password postgres` in `psql`.

**DataGrip connection:**
- Driver: PostgreSQL
- Host: `192.168.0.2`
- Port: `5432`
- Database: `mydb` (must not be left blank — causes "Unable to parse URL")
- User: `postgres`
- Password: `<set>`
- JDBC URL form: `jdbc:postgresql://192.168.0.2:5432/mydb`

---

## MongoDB

**Config file edited:** `/etc/mongod.conf`
```yaml
net:
  port: 27017
  bindIp: 0.0.0.0
security:
  authorization: enabled
```

**Auth setup (in `mongosh`):**
```js
use admin
db.createUser({ user: "admin", pwd: "yourpassword", roles: ["root"] })
```

**Commands run:**
```bash
sudo systemctl restart mongod
sudo ufw allow 27017
```

**DataGrip connection:**
- Driver: MongoDB
- Host: `192.168.0.2`
- Port: `27017`
- User: `admin`
- Password: `<set>`
- Auth DB: `admin`

---

## Redis

**Config file edited:** `/etc/redis/redis.conf`
```
bind 0.0.0.0
protected-mode no
requirepass yourpassword
```

**Commands run:**
```bash
sudo systemctl restart redis-server
sudo ufw allow 6379
```

**DataGrip connection:**
- Driver: Redis
- Host: `192.168.0.2`
- Port: `6379`
- Password: `<set>`

---

## Neo4j

**Config file edited:** `/etc/neo4j/neo4j.conf`
```
server.default_listen_address=0.0.0.0
```

**Commands run:**
```bash
sudo systemctl restart neo4j
sudo ufw allow 7687
sudo ufw allow 7474
```

**Auth:** default login `neo4j` / `neo4j` — forced password change on first connect via:
```bash
cypher-shell -a bolt://192.168.0.2:7687 -u neo4j
```

**DataGrip connection:**
- Driver: Neo4j
- URL: `bolt://192.168.0.2:7687`
- User: `neo4j`
- Password: `<set after first login>`

---

## Qdrant (vector database)

Runs as a Docker container (not a native systemd service) — storage persisted to `/opt/qdrant/storage`.

**Install/run command:**
```bash
sudo docker run -d \
  --name qdrant \
  --restart unless-stopped \
  -p 6333:6333 \
  -p 6334:6334 \
  -v /opt/qdrant/storage:/qdrant/storage \
  qdrant/qdrant
```

**Ports:**
- `6333` — HTTP REST API + web dashboard (`http://192.168.0.2:6333/dashboard`)
- `6334` — gRPC API

**Auth:** none by default. To enable an API key, add `-e QDRANT__SERVICE__API_KEY=yourkey` to the `docker run` command (or set it in a mounted config file) and restart the container.

**Firewall:**
```bash
sudo ufw allow 6333
sudo ufw allow 6334
```

**DataGrip connection:** DataGrip does not have a native Qdrant driver — Qdrant isn't a traditional SQL/JDBC database. Connect instead via:
- Web dashboard: `http://192.168.0.2:6333/dashboard`
- REST API: `http://192.168.0.2:6333`
- Official clients: `qdrant-client` (Python), `@qdrant/js-client-rest` (JS/TS), or the Rust `qdrant-client` crate

**Useful commands:**
```bash
docker logs qdrant              # view logs
docker restart qdrant           # restart
docker exec -it qdrant sh       # shell into container
```

---

## Firewall (ufw) quick reference

```bash
sudo ufw status              # check current rules
sudo ufw allow <port>        # open a port to everyone
sudo ufw allow from <ip> to any port <port>   # restrict to one IP (safer)
```

Ports in use: `5432` (Postgres), `27017` (MongoDB), `6379` (Redis), `7687` + `7474` (Neo4j), `6333` + `6334` (Qdrant).

---

## Security note

All ports above are currently open to `0.0.0.0` (anyone who can reach the server). Fine for a home/LAN dev box. If this server ever gets public internet exposure, either:
- restrict `ufw` rules to your specific IP, or
- switch to SSH tunneling in DataGrip's SSH/SSL tab instead of exposing DB ports directly.
