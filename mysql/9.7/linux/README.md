# AxialDB for MySQL 9.7 — Linux x64

AxialDB keeps a columnar copy of the tables your reports use, and answers the heavy queries from that copy. MySQL is the first database this release supports. Your InnoDB tables stay the system of record. AxialDB does not write to them.

This download is free for **5 views**, **2 of them live** from the binlog. It does not expire. Read [TERMS.md](TERMS.md) before you rely on it in production: the free version is provided as-is, with no support agreement. A license file on this same engine raises the caps and is how support is agreed. Contact info@axialdb.com.

You need two processes. MySQL loads `ha_axialdb.so`. A separate systemd service, **axialdb-engine**, stores the copies and runs the analytical queries. MySQL does not start that service. The unit runs as **`User=mysql`**.

## What you need first

- MySQL Server **9.7**, 64-bit. The plugin must be built for the exact patch reported by `SELECT VERSION()`.
- Linux x86_64 with glibc **2.35** or newer (Ubuntu 22.04 and newer glibc distros, including Debian 12 and Arch). Alpine will not run it.
- `sudo`.
- The `mysql` user must be able to write `/var/lib/axialdb` and `/var/log/axialdb`. If those directories are owned by root, the sidecar exits at once and systemd stays at `activating`.

For **live** views only, MySQL itself must be a row-based replica source:

```sql
SELECT @@binlog_format, @@binlog_row_image, @@binlog_row_metadata, @@gtid_mode;
-- expect: ROW, FULL, FULL, ON
```

Changing those on a server that is already in production is a replication change. Plan it. Do not treat it as an install checkbox you can flip and restart blindly.

## Where the files go

These paths match the `axialdb.toml` in the zip.

| What | Path |
|------|------|
| Plugin and bridge | `@@plugin_dir` (often `/usr/lib/mysql/plugin/`) |
| Engine | `/usr/local/axialdb/axialdb-engine` |
| Config | `/etc/axialdb/axialdb.toml` |
| Columnar data and catalog | `/var/lib/axialdb/data/` |
| Engine log | `/var/log/axialdb/axialdb-engine.log` |
| Service | `axialdb-engine.service` |

The zip contains the engine, `libaxialdb_mysql_bridge.so`, `install-axialdb-mysql-functions.sql`, `cdc-limitations.md`, `TERMS.md`, `THIRD-PARTY-NOTICES.md`, and `VERSION`. The plugin `.so` is a separate file on the GitHub release, named for your MySQL patch.

## Install

1. The plugin is a separate file on the same GitHub release as this zip. It is not one file for every MySQL patch.

   ```sql
   SELECT VERSION();
   ```

   Download `ha_axialdb-<version>-linux-x64.so`, where `<version>` is that string (`9.7.0` is `ha_axialdb-9.7.0-linux-x64.so`). If that file is not on the release, this AxialDB build does not support that MySQL patch.

   ```bash
   VERSION=9.7.0   # numeric prefix from SELECT VERSION(), drop a -log suffix
   PLUGIN_DIR=$(mysql -N -e "SELECT @@plugin_dir;")
   sudo cp "ha_axialdb-${VERSION}-linux-x64.so" "$PLUGIN_DIR/ha_axialdb.so"
   sudo cp libaxialdb_mysql_bridge.so "$PLUGIN_DIR/"
   ```

   The bridge comes from the zip. Do not rename it. The plugin loads `libaxialdb_mysql_bridge.so` from that same directory.

   When you later move to another 9.7 patch, replace only `ha_axialdb.so` with the file for the new `SELECT VERSION()`, then restart MySQL. Leave the engine and the bridge in place.

2. Engine:

   ```bash
   sudo mkdir -p /usr/local/axialdb
   sudo cp axialdb-engine /usr/local/axialdb/
   sudo chmod +x /usr/local/axialdb/axialdb-engine
   ```

3. Config and directories. The `chown` is required. Skip it and the service cannot open its log.

   ```bash
   sudo mkdir -p /etc/axialdb /var/lib/axialdb/data /var/log/axialdb
   sudo cp axialdb.toml /etc/axialdb/axialdb.toml
   sudo chown root:mysql /etc/axialdb/axialdb.toml
   sudo chmod 640 /etc/axialdb/axialdb.toml
   sudo chown -R mysql:mysql /var/lib/axialdb /var/log/axialdb
   ```

   `chmod 640` keeps the replication password, once you add it, readable by root and the `mysql` group only. The sidecar runs as `mysql`.

   The shipped toml uses port **3306**. If your MySQL listens elsewhere, change `[cdc] port` before you enable capture.

4. Tell mysqld where the config is. The unit name is often `mysql` and sometimes `mysqld`. Use the one `systemctl status` shows.

   ```bash
   sudo mkdir -p /etc/systemd/system/mysql.service.d
   sudo tee /etc/systemd/system/mysql.service.d/axialdb.conf >/dev/null <<'EOF'
   [Service]
   Environment=AXIALDB_CONFIG=/etc/axialdb/axialdb.toml
   EOF
   sudo systemctl daemon-reload
   ```

5. Sidecar, from the unit file in the zip:

   ```bash
   sudo cp axialdb-engine.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable --now axialdb-engine
   systemctl is-active axialdb-engine
   ```

   You want `active`. `activating` almost always means the `mysql` user cannot write the log directory. See below.

6. Restart MySQL so it sees `AXIALDB_CONFIG`:

   ```bash
   sudo systemctl restart mysql
   ```

7. Register the plugin and the helper functions once:

   ```sql
   INSTALL PLUGIN axialdb SONAME 'ha_axialdb.so';
   ```

   Then `mysql -D mysql < install-axialdb-mysql-functions.sql`.

8. Check the link:

   ```sql
   SELECT axialdb_init();
   ```

   And from the shell: `ss -ltn | grep 9742` should show `127.0.0.1:9742`.

## First view

A snapshot copies the query result once. Later changes to the source are not in it until you create it again.

```sql
CREATE DATABASE IF NOT EXISTS demo_perf;
CREATE TABLE demo_perf.t ENGINE=AXIALDB AS
SELECT 1 AS id, 'hello' AS msg;
SELECT * FROM demo_perf.t;
```

`GROUP BY` belongs in the query you run against the view. That is the fast path. The numbers we published, including the WSL2 set, are on [axialdb.com/measurements](https://axialdb.com/measurements.html). WSL2 is not a bare-metal Linux server. Measure on yours.

## Live view (binlog)

`[cdc] enabled` is **false** in the shipped toml. Turn it on only after the server settings above are true and this user exists. Point the host at `127.0.0.1` if MySQL is local, and set `port` to the real port (the file says 3306).

```sql
CREATE USER 'axialdb_cdc'@'127.0.0.1' IDENTIFIED BY 'choose-a-password';
GRANT REPLICATION SLAVE, REPLICATION CLIENT, SELECT ON *.* TO 'axialdb_cdc'@'127.0.0.1';
```

Put the password in `/etc/axialdb/axialdb.toml`, set `enabled = true`, and `sudo systemctl restart axialdb-engine`.

A live view accepts one InnoDB table, or a fact table left-joined to its dimensions on the dimension primary key, with plain source columns and the primary keys included. Anything else fails the `CREATE`. It does not silently become a snapshot. Details: [cdc-limitations.md](cdc-limitations.md).

```sql
-- Replace your_db.orders with an InnoDB table you already have.
-- Include its primary key. See cdc-limitations.md.
CREATE TABLE your_db.orders_av ENGINE=AXIALDB COMMENT='cdc' AS
SELECT id, customer_id, total
FROM your_db.orders;

SELECT axialdb_cdc_status('your_db', 'orders_av');
```

Wait for `healthy`. Until then a `SELECT` on that table is refused. Source inserts, updates, and deletes then apply on their own, usually within a few seconds. `TRUNCATE` on the source means recreate the view. Do not change a primary key on a watched source table: the new key is applied and the old key remains.

A sixth view, or a third live view, is refused. Existing views stay. To raise the cap, place `axialdb.lic` beside `/etc/axialdb/axialdb.toml` and restart `axialdb-engine`.

## If you already installed 0.1.x

Remove the old plugin, unit, and engine, then install this zip on the paths above and create the views again. Do not reuse an old config whose paths differ from this toml.

## If the sidecar will not start

`journalctl -u axialdb-engine -n 30` and look for `Permission denied` on the log file.

```bash
sudo mkdir -p /var/lib/axialdb/data /var/log/axialdb
sudo chown -R mysql:mysql /var/lib/axialdb /var/log/axialdb
sudo systemctl restart axialdb-engine
systemctl is-active axialdb-engine
```

`ls -ld /var/log/axialdb /var/lib/axialdb` should show `mysql mysql`.

On Ubuntu, AppArmor can stop mysqld from reading `/etc/axialdb/axialdb.toml` or connecting to `127.0.0.1:9742`. If `axialdb_init()` fails and the sidecar is active, check `journalctl -u mysql` and the AppArmor denials before changing the unit.

## Remove it

```sql
DROP TABLE IF EXISTS your_db.orders_av;
DROP FUNCTION IF EXISTS axialdb_init;
DROP FUNCTION IF EXISTS axialdb_drop_view;
DROP FUNCTION IF EXISTS axialdb_cdc_publish;
DROP FUNCTION IF EXISTS axialdb_cdc_status;
UNINSTALL PLUGIN axialdb;
```

`sudo systemctl disable --now axialdb-engine`, then remove the unit, the two `.so` files, `/usr/local/axialdb/axialdb-engine`, `/etc/axialdb`, and the mysqld drop-in if you do not want them. Deleting `/var/lib/axialdb` deletes the columnar copies.
