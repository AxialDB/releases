# AxialDB engine — Windows x64

AxialDB keeps a columnar copy of the tables your reports use and answers the heavy queries from that copy. One engine reads MySQL servers and MongoDB replica sets, on the same machine or on others, and one query can join tables from several of them. Your databases stay the system of record; AxialDB does not write to them.

This package is the engine: the server process, the `axialdb` command line, and the ODBC and JDBC drivers for reporting tools. It is all you need to make tables from MySQL and MongoDB and to query them. To create and query AxialDB tables from inside MySQL as well, add the **MySQL shim package** to that MySQL server; its guide says how.

The download is free for **5 tables**, **2 of them live**. It does not expire. Read [TERMS.md](TERMS.md) before you rely on it in production: the free version is provided as-is, with no support agreement. A license file on this same engine lifts the caps and is how support is agreed. Contact info@axialdb.com.

## What is in the zip

| File | What it is |
|------|------------|
| `axialdb-engine.exe` | The engine |
| `axialdb.exe` | The command line |
| `axialdb.toml` | The engine's config |
| `odbc\` | The ODBC driver, its install script, the Tableau customization file with its install script, and the driver's guide (`odbc\README.md`): Tableau, Power BI, Excel, and other ODBC programs |
| `jdbc\` | The JDBC driver and its guide (`jdbc\README.md`): DBeaver and other Java programs |
| `live-tables.md` | What a live table can be, for MySQL and MongoDB |
| `remote-engine.md` | The engine on a machine of its own, with secrets and TLS |
| `TERMS.md`, `THIRD-PARTY-NOTICES.md`, `VERSION` | Terms, notices, and the build |

## What you need first

- Windows x64 and an administrator PowerShell for the install.
- A source: MySQL **9.7**, or MongoDB **8.0** or newer as a replica set. What each needs for live tables is under "Connect a MySQL server" and "Connect a MongoDB replica set" below.

## Where the files go

These paths match the `axialdb.toml` in the zip. If you move anything, change the config to match.

| What | Path |
|------|------|
| Engine and command line | `C:\Program Files\AxialDB\` |
| Config | `C:\ProgramData\AxialDB\mysql\axialdb.toml` |
| Columnar data and catalog | `C:\ProgramData\AxialDB\mysql\data\` |
| Log | `C:\ProgramData\AxialDB\mysql\logs\axialdb-engine.log` |
| Service | `AxialDBEngine`, as LocalSystem |

## Install

Administrator PowerShell, in the folder of the unpacked zip.

1. The engine and the command line, and the command line on the `PATH`:

   ```powershell
   New-Item -ItemType Directory -Force -Path "C:\Program Files\AxialDB" | Out-Null
   Copy-Item .\axialdb-engine.exe, .\axialdb.exe "C:\Program Files\AxialDB\"
   $path = [Environment]::GetEnvironmentVariable("Path", "Machine")
   if ($path -notlike "*C:\Program Files\AxialDB*") {
     [Environment]::SetEnvironmentVariable("Path", "$path;C:\Program Files\AxialDB", "Machine")
   }
   ```

2. The config and the folders. The `icacls` line keeps the database passwords, once you add them, readable only by SYSTEM and administrators.

   ```powershell
   New-Item -ItemType Directory -Force -Path `
     C:\ProgramData\AxialDB\mysql\data, `
     C:\ProgramData\AxialDB\mysql\logs | Out-Null
   Copy-Item .\axialdb.toml C:\ProgramData\AxialDB\mysql\axialdb.toml
   icacls C:\ProgramData\AxialDB\mysql\axialdb.toml /inheritance:r /grant:r "SYSTEM:(F)" "Administrators:(F)"
   ```

3. The service:

   ```powershell
   $config = "C:\ProgramData\AxialDB\mysql\axialdb.toml"
   $engine = "C:\Program Files\AxialDB\axialdb-engine.exe"
   New-Service -Name AxialDBEngine -BinaryPathName "`"$engine`" --config `"$config`"" `
     -DisplayName "AxialDB engine" -StartupType Automatic
   sc.exe failure AxialDBEngine reset= 86400 actions= restart/60000/restart/60000/restart/60000
   Start-Service AxialDBEngine
   Get-Service AxialDBEngine
   ```

4. Check it, in a new PowerShell window (it reads the new `PATH`):

   ```powershell
   axialdb sources
   ```

   It lists the sources of the config with the state of each. The shipped config has one MySQL source, `mysql`, on `127.0.0.1:3306`, with no accounts yet.

The engine listens on `127.0.0.1:9742`: only programs on this machine reach it. To serve MySQL servers and reporting tools on other machines, see [remote-engine.md](remote-engine.md).

## Connect a MySQL server

Each MySQL server is one `[sources.<name>]` entry in `C:\ProgramData\AxialDB\mysql\axialdb.toml`. The shipped entry is `[sources.mysql]`; give a second server an entry of its own with another name. Set `host` and `port` to where the engine reaches the server.

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

In the config, under the source, set `user = "axialdb"`, `password`, `capture_user = "axialdb_cdc"`, and `capture_password`, then `Restart-Service AxialDBEngine`. To read the binlog from a replica, add `capture_host` and `capture_port`. `axialdb sources` shows `ok` for the capture once it is connected, or the reason it is not.

## Connect a MongoDB replica set

Uncomment the `[sources.mongo]` entry at the end of the config and write your replica set's URI with an account that has the `read` role on the databases your tables read. One member is enough; a standalone server has no change stream, and sharded clusters are not supported.

For **live** tables, enable post-images once on each source collection (a DBA's task; the engine's account does not need the right):

```javascript
db.runCommand({ collMod: "customers", changeStreamPreAndPostImages: { enabled: true } })
```

Then `Restart-Service AxialDBEngine`.

## First tables

A **snapshot** copies a query's result once. A **live** table follows its source; what its query may contain is in [live-tables.md](live-tables.md).

```powershell
# MySQL: the name is the MySQL database and table, as on that server.
axialdb create-table shop.orders_snap --source mysql `
  --query "SELECT o.id, o.created_at, c.country, o.total FROM shop.orders o JOIN shop.customers c ON c.id = o.customer_id"
axialdb create-table shop.orders_live --source mysql --mode live `
  --query "SELECT id, customer_id, created_at, total FROM shop.orders"

# MongoDB: the name is the AxialDB table; FROM names the Mongo database and collection.
axialdb create-table crm.customers --source mongo --mode live `
  --query "SELECT _id, CAST(customer_id AS BIGINT) AS customer_id, address.state AS state FROM crm.customers"

axialdb tables
axialdb query "SELECT schema_name, table_name, status FROM axialdb.tables"
axialdb query "SELECT c.state, SUM(o.total) AS total FROM shop.orders_live o JOIN crm.customers c ON c.customer_id = o.customer_id GROUP BY c.state"
```

A live table answers queries once its status is `healthy`. On a MySQL server with the AxialDB plugin the same table also appears in MySQL, and can be queried there.

`axialdb drop-table shop.orders_snap` removes a table. `axialdb --help` lists every command.

## Reporting tools

- **ODBC** (Tableau, Power BI, Excel): register the driver with `.\odbc\register-axialdb-odbc.ps1` from an administrator PowerShell, then connect with `Driver={AxialDB};Server=127.0.0.1;Port=9742;DbIdentity=<schema>;`. For Tableau Desktop also run `.\odbc\install-tableau-tdc.ps1` and restart Tableau. Details in `odbc\README.md`.
- **JDBC** (DBeaver): `jdbc\axialdb-jdbc.jar` with `jdbc\axialdb_jdbc.dll` beside it, URL `jdbc:axialdb://127.0.0.1:9742`. Details in `jdbc\README.md`.

## Keep the table definitions

```powershell
axialdb export-tables > tables.json
```

writes every table's definition. After a source server is replaced, or on a new engine machine, `Get-Content tables.json | axialdb create-tables` creates them again under the same names. Keep the file off the engine's machine, for example from a nightly task.

## Free version and license

A sixth table, or a third live table, is refused; existing tables stay. Place `axialdb.lic` beside `C:\ProgramData\AxialDB\mysql\axialdb.toml` and `Restart-Service AxialDBEngine` to lift the caps.

## Upgrading from 5.0.0

This release does not read the tables of 5.0.0. With the old build still installed, drop every AxialDB table (in MySQL, `DROP TABLE` of each). Then stop MySQL and AxialDBEngine, install this package and the MySQL shim package, empty `C:\ProgramData\AxialDB\mysql\data`, write the new config from the one in this zip (the `[cdc]` section of 5.0.0 is now a `[sources.<name>]` entry), start AxialDBEngine, then MySQL, and create the tables again.

## If something fails

| What you see | What it usually means |
|--------------|------------------------|
| `axialdb` is not recognized | The PowerShell window was opened before the `PATH` changed. Open a new one |
| `cannot reach the engine at 127.0.0.1:9742` | AxialDBEngine is stopped. `Get-Service AxialDBEngine`, and the log below |
| A live create fails at once | The query is outside [live-tables.md](live-tables.md), or `user` or `capture_user` of the source is empty. The error says which |
| Status stays `catching_up` | The engine is still applying the source's changes since the first copy. Queries are refused until it is `healthy` |

Engine log: `C:\ProgramData\AxialDB\mysql\logs\axialdb-engine.log`.

## Remove it

```powershell
Stop-Service AxialDBEngine
sc.exe delete AxialDBEngine
Remove-Item -Recurse "C:\Program Files\AxialDB"
.\odbc\register-axialdb-odbc.ps1 -Remove
```

Then take `C:\Program Files\AxialDB` out of the Machine `PATH`. Deleting `C:\ProgramData\AxialDB\mysql` deletes the config and the columnar copies.
