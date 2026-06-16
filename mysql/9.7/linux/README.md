# AxialDB for MySQL 9.7 - Linux x64 eval

Pre-release eval only. See [EVALUATION_LICENSE.md](../../../EVALUATION_LICENSE.md) and the [GitHub Release](https://github.com/AxialDB/releases/releases) for this version.

AxialDB adds an **AXIALDB** storage engine and a **sidecar** (`axialdb-engine`). **mysqld does not start the sidecar** (`helper.auto_spawn = false`). You must run **axialdb-engine.service** before `axialdb_init()` or CTAS.

## Zip contents

| File | Purpose |
|------|---------|
| `ha_axialdb.so` | Storage engine plugin |
| `libaxialdb_mysql_bridge.so` | Bridge (same folder as plugin) |
| `axialdb-engine` | Sidecar analytics engine |
| `axialdb.toml` | Example config (copy elsewhere; edit paths) |
| `axialdb-engine.service` | systemd unit for the sidecar |
| `install-axialdb-mysql-functions.sql` | UDF registration (`.so` SONAME) |
| `VERSION` | Build-ID for support |
| `README.md` | This file |

## Default paths (match `axialdb.toml`)

| Item | Path |
|------|------|
| Plugins | `@@plugin_dir` (typically `/usr/lib/mysql/plugin/`) |
| Engine | `/usr/local/axialdb/axialdb-engine` |
| Config | `/etc/axialdb/axialdb.toml` |
| Data / catalog | `/var/lib/axialdb/data/` |
| Engine log | `/var/log/axialdb/axialdb-engine.log` |
| Sidecar unit | **axialdb-engine.service** |
| MySQL datadir (optional) | `/var/lib/mysql` — janitor only; see below |

## Config (`axialdb.toml`)

Copy to `/etc/axialdb/axialdb.toml`; set **`AXIALDB_CONFIG`** for **mysqld** (drop-in) and the sidecar unit.

| Setting | Default | Notes |
|---------|---------|--------|
| `data.axialdb_data_dir` | `/var/lib/axialdb/data` | Parquet + `catalog.db` |
| `data.mysql_datadir` | `/var/lib/mysql` | **Optional.** Janitor-only: read-only check for `{schema}/{table}.sdi` under MySQL `@@datadir`. Removes stale **published** catalog rows when the MySQL table is gone. Omit the key (or unset **`AXIALDB_MYSQL_DATADIR`** on the engine) to skip. Does not affect CTAS or queries. |
| `helper.executable` | `/usr/local/axialdb/axialdb-engine` | Must match unit `ExecStart` |
| `helper.service_name` | `axialdb-engine` | systemd unit basename |
| `helper.auto_spawn` | `false` | Sidecar via systemd, not mysqld |
| `logging.file` | `/var/log/axialdb/axialdb-engine.log` | Engine log |

Confirm MySQL datadir: `mysql -N -e "SELECT @@datadir;"` and align `mysql_datadir`.

## Prerequisites

- MySQL Server **9.7** x64 (plugin major must match).
- `sudo` for plugin copy, config, and systemd.
- `mysql` user (or your mysqld account) needs write access to `axialdb_data_dir` and the log file.
- **`axialdb-engine.service` runs as `User=mysql`.** If `/var/lib/axialdb` or `/var/log/axialdb` are root-owned, the sidecar exits immediately with `Permission denied` on the log file and systemd stays **activating**.

## Install (from zip)

1. **Plugins** (both `.so` in `plugin_dir`; `RPATH=$ORIGIN` loads the bridge from the same directory):

   ```bash
   PLUGIN_DIR=$(mysql -N -e "SELECT @@plugin_dir;")
   sudo cp ha_axialdb.so libaxialdb_mysql_bridge.so "$PLUGIN_DIR/"
   ```

2. **Engine**:

   ```bash
   sudo mkdir -p /usr/local/axialdb
   sudo cp axialdb-engine /usr/local/axialdb/
   sudo chmod +x /usr/local/axialdb/axialdb-engine
   ```

3. **Config** (create dirs, install config, **grant `mysql` ownership** — required before starting the sidecar):

   ```bash
   sudo mkdir -p /etc/axialdb /var/lib/axialdb/data /var/log/axialdb
   sudo cp axialdb.toml /etc/axialdb/axialdb.toml
   sudo chown -R mysql:mysql /var/lib/axialdb /var/log/axialdb
   ```

   The unit runs as **`User=mysql`**. Do not skip `chown` — without it, `axialdb-engine` cannot open `/var/log/axialdb/axialdb-engine.log` or write Parquet under `/var/lib/axialdb/data/`.

   Edit `/etc/axialdb/axialdb.toml` if you changed engine or data paths.

4. **`AXIALDB_CONFIG` for mysqld** — drop-in (adjust unit name if not `mysql`):

   ```bash
   sudo mkdir -p /etc/systemd/system/mysql.service.d
   sudo tee /etc/systemd/system/mysql.service.d/axialdb.conf >/dev/null <<'EOF'
   [Service]
   Environment=AXIALDB_CONFIG=/etc/axialdb/axialdb.toml
   EOF
   sudo systemctl daemon-reload
   ```

5. **Sidecar service** (from zip):

   ```bash
   sudo cp axialdb-engine.service /etc/systemd/system/
   # Edit ExecStart / Environment if you changed paths in step 3
   sudo systemctl daemon-reload
   sudo systemctl enable --now axialdb-engine
   ```

6. **Restart MySQL** (pick up `AXIALDB_CONFIG`):

   ```bash
   sudo systemctl restart mysql
   ```

7. **Plugin + UDFs**:

   ```sql
   INSTALL PLUGIN axialdb SONAME 'ha_axialdb.so';
   ```

   Then: `mysql -D mysql < install-axialdb-mysql-functions.sql`

8. **Verify** (sidecar must be active):

   ```bash
   systemctl is-active mysql axialdb-engine   # both: active
   ss -ltn | grep 9742                        # 127.0.0.1:9742 LISTEN
   ```

   ```sql
   SELECT axialdb_init();
   CREATE DATABASE IF NOT EXISTS demo_perf;
   DROP TABLE IF EXISTS demo_perf.t;
   CREATE TABLE demo_perf.t ENGINE=AXIALDB AS SELECT 1 AS x, 'hello' AS msg;
   SELECT * FROM demo_perf.t;
   ```

## Troubleshooting

### `axialdb-engine` stuck **activating** / `Permission denied` on log file

Journal shows e.g. `open log file /var/log/axialdb/axialdb-engine.log: Permission denied`.

```bash
sudo mkdir -p /var/lib/axialdb/data /var/log/axialdb
sudo chown -R mysql:mysql /var/lib/axialdb /var/log/axialdb
sudo systemctl restart axialdb-engine
systemctl is-active axialdb-engine
```

Confirm ownership: `ls -ld /var/log/axialdb /var/lib/axialdb` → `mysql mysql`.

### CTAS or GROUP BY very slow on Linux (minutes for small LIMIT)

Older eval builds omitted `TCP_NODELAY` on loopback IPC (`127.0.0.1:9742`), causing ~20 ms stalls per bridge round-trip (Nagle + delayed ACK). Symptom: wide CTAS orders of magnitude slower than Windows; `ss -tni | grep 9742` shows high `rtt` vs `minrtt`.

**Fix:** use **v0.1.1** or later (sets `TCP_NODELAY` on bridge + sidecar). Redeploy `libaxialdb_mysql_bridge.so` and `axialdb-engine`; restart both services.

## Remote clients

Grant the client host if needed. JDBC (DBeaver): `allowPublicKeyRetrieval=true`, `useSSL=false` for local eval.

## Uninstall

```sql
DROP FUNCTION IF EXISTS axialdb_init;
DROP FUNCTION IF EXISTS axialdb_drop_view;
UNINSTALL PLUGIN axialdb;
```

`sudo systemctl disable --now axialdb-engine`, remove unit, plugins, engine binary, `/etc/axialdb`, and the mysqld drop-in if unused.
