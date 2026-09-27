# AxialDB for MySQL 9.7 — Linux x64

AxialDB keeps a columnar copy of the tables your reports use, and answers the heavy queries from that copy. MySQL is the first database this release supports. Your InnoDB tables stay the system of record. AxialDB does not write to them.

This download is free for **5 views**, **2 of them live** from the binlog. It does not expire. Read [TERMS.md](TERMS.md) before you rely on it in production: the free version is provided as-is, with no support agreement. A license file on this same engine raises the caps and is how support is agreed. Contact info@axialdb.com.

You need two processes. MySQL loads `ha_axialdb.so`. A separate systemd service, **axialdb-engine**, stores the copies and runs the analytical queries. MySQL does not start that service. The unit runs as **`User=mysql`**.

## What you need first

- MySQL Server **9.7**, 64-bit. The plugin must match that server.
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

The zip also contains `install-axialdb-mysql-functions.sql`, `cdc-limitations.md`, `TERMS.md`, and `VERSION`.

## Install

1. Both shared libraries go in the plugin directory. The plugin loads the bridge from that same directory.

   ```bash
   PLUGIN_DIR=$(mysql -N -e "SELECT @@plugin_dir;")
   sudo cp ha_axialdb.so libaxialdb_mysql_bridge.so "$PLUGIN_DIR/"
   ```

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
   sudo chown -R mysql:mysql /var/lib/axialdb /var/log/axialdb
   ```

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
CREATE TABLE demo_perf.orders_av ENGINE=AXIALDB COMMENT='cdc' AS
SELECT id, customer_id, total
FROM demo_perf.orders;

SELECT axialdb_cdc_status('demo_perf', 'orders_av');
```

Wait for `healthy`. Until then a `SELECT` on that table is refused. Source inserts, updates, and deletes then apply on their own, usually within a few seconds. `TRUNCATE` on the source means recreate the view. Do not change a primary key on a watched source table: the new key is applied and the old key remains.

A sixth view, or a third live view, is refused. Existing views stay. To raise the cap, place `axialdb.lic` beside `/etc/axialdb/axialdb.toml` and restart `axialdb-engine`.

## If the sidecar will not start

`journalctl -u axialdb-engine -n 30` and look for `Permission denied` on the log file.

```bash
sudo mkdir -p /var/lib/axialdb/data /var/log/axialdb
sudo chown -R mysql:mysql /var/lib/axialdb /var/log/axialdb
sudo systemctl restart axialdb-engine
systemctl is-active axialdb-engine
```

`ls -ld /var/log/axialdb /var/lib/axialdb` should show `mysql mysql`.

## Remove it

```sql
DROP FUNCTION IF EXISTS axialdb_init;
DROP FUNCTION IF EXISTS axialdb_drop_view;
UNINSTALL PLUGIN axialdb;
```

`sudo systemctl disable --now axialdb-engine`, then remove the unit, the two `.so` files, `/usr/local/axialdb/axialdb-engine`, `/etc/axialdb`, and the mysqld drop-in if you do not want them. Deleting `/var/lib/axialdb` deletes the columnar copies.
