# AxialDB for MySQL 9.7 - Linux x64 eval

Self-managed **MySQL Community 9.7** (x64) with AxialDB storage engine and sidecar.

Pre-release eval only. See [EVALUATION_LICENSE.md](../../../EVALUATION_LICENSE.md) and the [GitHub Release](https://github.com/AxialDB/releases/releases) for this version.

## Zip contents

| File | Purpose |
|------|---------|
| `ha_axialdb.so` | AxialDB storage engine plugin |
| `libaxialdb_mysql_bridge.so` | Bridge library (same folder as engine plugin) |
| `axialdb-engine` | Sidecar analytics engine |
| `axialdb.toml` | **Example config** with default paths (edit before use) |
| `install-axialdb-mysql-functions.sql` | UDF registration SQL (`.so` SONAME) |
| `VERSION` | Release identity and Build-ID (for support) |
| `README.md` | This file |

## Config (`axialdb.toml`)

Copy to a permanent location (for example `/etc/axialdb/axialdb.toml`), edit paths for your environment, and point **`AXIALDB_CONFIG`** at that file for **both `mysqld` and the sidecar**.

Typical fields to review:

| Setting | Default | Change if... |
|---------|---------|--------------|
| `data.axialdb_data_dir` | `/var/lib/axialdb/data` | Data should live elsewhere |
| `helper.executable` | `/usr/local/axialdb/axialdb-engine` | Engine installed elsewhere |
| `logging.file` | `/var/log/axialdb/axialdb-engine.log` | Logs should go elsewhere |

Create data and log directories and ensure the MySQL service account can write to `axialdb_data_dir` (eval layout often uses `chown` to the admin user running the engine).

## Prerequisites

- MySQL Server **9.7** x64 (Oracle `.deb` or equivalent; major must match the plugin build).
- Default `plugin_dir` (typically `/usr/lib/mysql/plugin/`).
- `sudo` for copying plugins, config, and optional systemd drop-ins.

## Install

1. **Copy plugins** to MySQL `plugin_dir` (both `.so` files):

   ```bash
   PLUGIN_DIR=$(mysql -N -e "SELECT @@plugin_dir;")
   sudo cp ha_axialdb.so libaxialdb_mysql_bridge.so "$PLUGIN_DIR/"
   ```

   The plugin is built with `RPATH=$ORIGIN` so `ha_axialdb.so` loads the bridge from the same directory.

2. **Copy engine**:

   ```bash
   sudo mkdir -p /usr/local/axialdb
   sudo cp axialdb-engine /usr/local/axialdb/
   sudo chmod +x /usr/local/axialdb/axialdb-engine
   ```

3. **Config** - copy `axialdb.toml` to `/etc/axialdb/axialdb.toml`, edit paths, create directories:

   ```bash
   sudo mkdir -p /etc/axialdb /var/lib/axialdb/data /var/log/axialdb
   sudo cp axialdb.toml /etc/axialdb/axialdb.toml
   sudo chown -R <admin-user>:<admin-group> /var/lib/axialdb
   ```

4. **`AXIALDB_CONFIG` for mysqld** (required) - the MySQL **server** process must see this variable. Example systemd drop-in:

   ```bash
   sudo mkdir -p /etc/systemd/system/mysql.service.d
   sudo tee /etc/systemd/system/mysql.service.d/axialdb.conf >/dev/null <<'EOF'
   [Service]
   Environment=AXIALDB_CONFIG=/etc/axialdb/axialdb.toml
   EOF
   sudo systemctl daemon-reload
   ```

   Adjust the unit name if your service is not `mysql` (`systemctl list-units | grep -i mysql`).

5. **Start sidecar** before AxialDB DML:

   ```bash
   /usr/local/axialdb/axialdb-engine --config /etc/axialdb/axialdb.toml \
     >> /var/log/axialdb/axialdb-engine.log 2>&1 &
   ```

   Or install a systemd unit (optional; not included in eval zip).

6. **Restart MySQL** (pick up `AXIALDB_CONFIG`):

   ```bash
   sudo systemctl restart mysql
   ```

7. **Register plugin and UDFs** (once per server restart):

   ```sql
   INSTALL PLUGIN axialdb SONAME 'ha_axialdb.so';
   ```

   Then run `install-axialdb-mysql-functions.sql` (e.g. `mysql -D mysql < install-axialdb-mysql-functions.sql`).

8. **Verify**:

   ```sql
   SELECT axialdb_init();
   CREATE DATABASE IF NOT EXISTS demo_perf;
   DROP TABLE IF EXISTS demo_perf.t;
   CREATE TABLE demo_perf.t ENGINE=AXIALDB AS SELECT 1 AS x, 'hello' AS msg;
   SELECT * FROM demo_perf.t;
   ```

## Remote clients (DBeaver, etc.)

MySQL user grants are per host (`user@host`). Allow your client host if needed:

```sql
CREATE USER IF NOT EXISTS 'your_user'@'%' IDENTIFIED BY '...';
GRANT ALL PRIVILEGES ON *.* TO 'your_user'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

JDBC (DBeaver): set driver properties `allowPublicKeyRetrieval=true`, `useSSL=false` for local eval.

## Data location

- Parquet and `catalog.db`: under `axialdb_data_dir` in your config (default `/var/lib/axialdb/data/`).
- Engine log: path in `logging.file` in your config.

## Uninstall

```sql
UNINSTALL PLUGIN axialdb;
```

Stop `axialdb-engine`, remove `.so` files and installed binaries, remove systemd drop-in and `/etc/axialdb` if no longer needed.
