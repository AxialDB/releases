# AxialDB engine — Linux x64

AxialDB keeps a columnar copy of the tables your reports use and answers the heavy queries from that copy. One engine reads MySQL servers and MongoDB replica sets, on the same machine or on others, and one query can join tables from several of them. Your databases stay the system of record; AxialDB does not write to them.

This package is the engine: the server process, the `axialdb` command line, and the ODBC and JDBC drivers for reporting tools. It is all you need to make tables from MySQL and MongoDB and to query them. To create and query AxialDB tables from inside MySQL as well, add the **MySQL shim package** to that MySQL server; its guide says how.

The download is free for **5 tables**, **2 of them live**. It does not expire. Read [TERMS.md](TERMS.md) before you rely on it in production: the free version is provided as-is, with no support agreement. A license file on this same engine lifts the caps and is how support is agreed. Contact info@axialdb.com.

## What is in the zip

| File | What it is |
|------|------------|
| `axialdb-engine` | The engine |
| `axialdb` | The command line |
| `axialdb.toml` | The engine's config |
| `axialdb-engine.service` | The systemd unit |
| `odbc/` | The ODBC driver, its install script, and its guide (`odbc/README.md`): Tableau, Power BI, and other ODBC programs |
| `jdbc/` | The JDBC driver and its guide (`jdbc/README.md`): DBeaver and other Java programs |
| `live-tables.md` | What a live table can be, for MySQL and MongoDB |
| `remote-engine.md` | The engine on a machine of its own, with secrets and TLS |
| `TERMS.md`, `THIRD-PARTY-NOTICES.md`, `VERSION` | Terms, notices, and the build |

## What you need first

- Linux x86_64 with glibc **2.35** or newer (Ubuntu 22.04 and later, Debian 12, and other distributions of that age). Alpine will not run it.
- `sudo`.
- A source: MySQL **9.7**, or MongoDB **8.0** or newer as a replica set. What each needs for live tables is under "Connect a MySQL server" and "Connect a MongoDB replica set" below.

## Where the files go

These paths match the `axialdb.toml` in the zip.

| What | Path |
|------|------|
| Engine | `/usr/local/axialdb/axialdb-engine` |
| Command line | `/usr/local/bin/axialdb` |
| Config | `/etc/axialdb/axialdb.toml` |
| Columnar data and catalog | `/var/lib/axialdb/data/` |
| Log | `/var/log/axialdb/axialdb-engine.log` |
| Service | `axialdb-engine.service`, as the system user `axialdb` |

## Install

1. An account for the engine:

   ```bash
   sudo useradd --system --no-create-home --shell /usr/sbin/nologin axialdb
   ```

2. The engine and the command line:

   ```bash
   sudo install -D -m 755 axialdb-engine /usr/local/axialdb/axialdb-engine
   sudo install -m 755 axialdb /usr/local/bin/axialdb
   ```

3. The config and the folders. The `chown` lines are required: without them the engine cannot open its log and stops at once.

   ```bash
   sudo mkdir -p /etc/axialdb /var/lib/axialdb/data /var/log/axialdb
   sudo cp axialdb.toml /etc/axialdb/axialdb.toml
   sudo chown root:axialdb /etc/axialdb/axialdb.toml
   sudo chmod 640 /etc/axialdb/axialdb.toml
   sudo chown -R axialdb:axialdb /var/lib/axialdb /var/log/axialdb
   ```

   `chmod 640` keeps the database passwords, once you add them, readable by root and the engine only.

4. The service:

   ```bash
   sudo cp axialdb-engine.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable --now axialdb-engine
   systemctl is-active axialdb-engine
   ```

   You want `active`. If it stays `activating`, see "If the engine will not start" below.

5. Check it:

   ```bash
   axialdb sources
   ```

   It lists the sources of the config with the state of each. The shipped config has one MySQL source, `mysql`, on `127.0.0.1:3306`, with no accounts yet.

The engine listens on `127.0.0.1:9742`: only programs on this machine reach it. To serve MySQL servers and reporting tools on other machines, see [remote-engine.md](remote-engine.md).

## Connect a MySQL server

Each MySQL server is one `[sources.<name>]` entry in `/etc/axialdb/axialdb.toml`. The shipped entry is `[sources.mysql]`; give a second server an entry of its own with another name. Set `host` and `port` to where the engine reaches the server.

The engine uses two MySQL accounts, and neither stands in for the other:

- `user` is the engine's own account. With it the engine reads the columns and keys of the source tables and the server's position when a live table is created, and it copies the rows of a table the command line creates on a server without the AxialDB plugin.
- `capture_user` reads the binlog, for live tables.

```sql
CREATE USER 'axialdb'@'127.0.0.1' IDENTIFIED BY 'choose-a-password';
GRANT SELECT, SHOW VIEW ON *.* TO 'axialdb'@'127.0.0.1';
CREATE USER 'axialdb_cdc'@'127.0.0.1' IDENTIFIED BY 'choose-another-password';
GRANT REPLICATION SLAVE, REPLICATION CLIENT, SELECT ON *.* TO 'axialdb_cdc'@'127.0.0.1';
```

Write the engine's address in place of `127.0.0.1` when the engine runs on another machine. `SELECT` for `axialdb` may be narrowed to the databases your tables read. On a server with the AxialDB plugin, the command line's creates and drops run as statements on that server, so there `axialdb` also needs `CREATE`, `DROP`, and `INSERT`.

For **live** tables the server writes a row-based binlog with GTIDs:

```sql
SELECT @@binlog_format, @@binlog_row_image, @@binlog_row_metadata, @@gtid_mode;
-- expect: ROW, FULL, FULL, ON
```

Changing those on a server in production is a replication change. Plan it.

In `/etc/axialdb/axialdb.toml`, under the source, set `user = "axialdb"`, `password`, `capture_user = "axialdb_cdc"`, and `capture_password`, then `sudo systemctl restart axialdb-engine`. To read the binlog from a replica, add `capture_host` and `capture_port`. `axialdb sources` shows `ok` for the capture once it is connected, or the reason it is not.

## Connect a MongoDB replica set

Uncomment the `[sources.mongo]` entry at the end of the config and write your replica set's URI with an account that has the `read` role on the databases your tables read. One member is enough; a standalone server has no change stream, and sharded clusters are not supported.

For **live** tables, enable post-images once on each source collection (a DBA's task; the engine's account does not need the right):

```javascript
db.runCommand({ collMod: "customers", changeStreamPreAndPostImages: { enabled: true } })
```

Then `sudo systemctl restart axialdb-engine`.

## First tables

A **snapshot** copies a query's result once. A **live** table follows its source; what its query may contain is in [live-tables.md](live-tables.md).

```bash
# MySQL: the name is the MySQL database and table, as on that server.
axialdb create-table shop.orders_snap --source mysql \
  --query "SELECT o.id, o.created_at, c.country, o.total FROM shop.orders o JOIN shop.customers c ON c.id = o.customer_id"
axialdb create-table shop.orders_live --source mysql --mode live \
  --query "SELECT id, customer_id, created_at, total FROM shop.orders"

# MongoDB: the name is the AxialDB table; FROM names the Mongo database and collection.
axialdb create-table crm.customers --source mongo --mode live \
  --query "SELECT _id, CAST(customer_id AS BIGINT) AS customer_id, address.state AS state FROM crm.customers"

axialdb tables
axialdb query "SELECT schema_name, table_name, status FROM axialdb.tables"
axialdb query "SELECT c.state, SUM(o.total) AS total FROM shop.orders_live o JOIN crm.customers c ON c.customer_id = o.customer_id GROUP BY c.state"
```

A live table answers queries once its status is `healthy`. On a MySQL server with the AxialDB plugin the same table also appears in MySQL, and can be queried there.

`axialdb drop-table shop.orders_snap` removes a table. `axialdb --help` lists every command.

## Reporting tools

- **ODBC** (Tableau, Power BI, Excel): register the driver with `sudo bash odbc/register-axialdb-odbc.sh`, then connect with `Driver={AxialDB};Server=127.0.0.1;Port=9742;DbIdentity=<schema>;`. Details, and the Tableau customization file `odbc/axialdb_odbc.tdc`, in `odbc/README.md`.
- **JDBC** (DBeaver): `jdbc/axialdb-jdbc.jar` with `jdbc/libaxialdb_jdbc.so` beside it, URL `jdbc:axialdb://127.0.0.1:9742`. Details in `jdbc/README.md`.

## Keep the table definitions

```bash
axialdb export-tables > tables.json
```

writes every table's definition. After a source server is replaced, or on a new engine machine, `axialdb create-tables < tables.json` creates them again under the same names. Keep the file off the engine's machine, for example from a nightly job.

## Free version and license

A sixth table, or a third live table, is refused; existing tables stay. Place `axialdb.lic` beside `/etc/axialdb/axialdb.toml` and `sudo systemctl restart axialdb-engine` to lift the caps.

## Upgrading from 5.0.0

This release does not read the tables of 5.0.0. With the old build still installed, drop every AxialDB table (in MySQL, `DROP TABLE` of each). Then stop MySQL and the old engine, install this package and the MySQL shim package, empty `/var/lib/axialdb/data`, write the new config from the one in this zip (the `[cdc]` section of 5.0.0 is now a `[sources.<name>]` entry), start the engine, then MySQL, and create the tables again. The 5.0.0 unit ran the engine as `mysql`; this one runs it as `axialdb`, so give `/var/lib/axialdb` and `/var/log/axialdb` to that account.

## If the engine will not start

`journalctl -u axialdb-engine -n 30` and look for `Permission denied` on the log file, or for a line about the config.

```bash
sudo chown -R axialdb:axialdb /var/lib/axialdb /var/log/axialdb
sudo systemctl restart axialdb-engine
systemctl is-active axialdb-engine
```

## Remove it

```bash
sudo systemctl disable --now axialdb-engine
sudo rm /etc/systemd/system/axialdb-engine.service /usr/local/bin/axialdb
sudo rm -r /usr/local/axialdb /etc/axialdb
```

Deleting `/var/lib/axialdb` deletes the columnar copies. `sudo bash odbc/register-axialdb-odbc.sh --remove` takes the ODBC driver away.
