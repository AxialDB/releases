# AxialDB for MySQL 9.7 — Windows x64

AxialDB keeps a columnar copy of the tables your reports use, and answers the heavy queries from that copy. MySQL is the first database this release supports. Your InnoDB tables stay the system of record. AxialDB does not write to them.

This download is free for **5 views**, **2 of them live** from the binlog. It does not expire. Read [TERMS.md](TERMS.md) before you rely on it in production: the free version is provided as-is, with no support agreement. A license file on this same engine raises the caps and is how support is agreed. Contact info@axialdb.com.

You need two processes. MySQL loads `ha_axialdb.dll`. A separate Windows service, **AxialDBEngine**, stores the copies and runs the analytical queries. MySQL does not start that service.

## What you need first

- MySQL Server **9.7**, 64-bit, with the default plugin directory.
- An administrator PowerShell for the install.
- The account that runs MySQL (often `NT AUTHORITY\NetworkService`) must be able to write the data and log folders below.

For **live** views only, MySQL itself must be a row-based replica source:

```sql
-- These must already be true. Changing them needs a MySQL restart
-- and, for GTID, a planned cutover. Do not flip them on a busy primary
-- without reading the MySQL replication manual.
SELECT @@binlog_format, @@binlog_row_image, @@binlog_row_metadata, @@gtid_mode;
-- expect: ROW, FULL, FULL, ON
```

The replication user is created later, after the files are in place.

## Where the files go

These paths match the `axialdb.toml` in the zip. If you move anything, change the toml to match.

| What | Path |
|------|------|
| Plugin and bridge | `C:\Program Files\MySQL\MySQL Server 9.7\lib\plugin\` |
| Engine | `C:\Program Files\AxialDB\axialdb-engine.exe` |
| Config | `C:\ProgramData\AxialDB\mysql\axialdb.toml` |
| Columnar data and catalog | `C:\ProgramData\AxialDB\mysql\data\` |
| Engine log | `C:\ProgramData\AxialDB\mysql\logs\axialdb-engine.log` |
| Service | `AxialDBEngine` |

The zip also contains `install-axialdb-mysql-functions.sql`, `cdc-limitations.md`, `TERMS.md`, and `VERSION`.

## Install

Stop MySQL first (`Stop-Service MySQL97`, or your service name).

1. Copy `ha_axialdb.dll` and `axialdb_mysql_bridge.dll` into the plugin folder. Both files must sit in that same folder. If the bridge is missing, MySQL reports error 126 when it loads the plugin.

2. Create `C:\Program Files\AxialDB\` and copy `axialdb-engine.exe` there.

3. Create the data and log folders and copy the config:

   ```powershell
   New-Item -ItemType Directory -Force -Path `
     C:\ProgramData\AxialDB\mysql\data, `
     C:\ProgramData\AxialDB\mysql\logs
   Copy-Item axialdb.toml C:\ProgramData\AxialDB\mysql\axialdb.toml
   ```

4. Tell MySQL where the config is, and let it find the bridge DLL. Both are Machine environment variables. Set them, then start MySQL only after the sidecar exists (step 5).

   - `AXIALDB_CONFIG` = `C:\ProgramData\AxialDB\mysql`
   - Prepend `C:\Program Files\MySQL\MySQL Server 9.7\lib\plugin` to the Machine `PATH`.

   The engine reads `AXIALDB_CONFIG` as the install root and opens `mysql\axialdb.toml` under it. That matches the comment at the top of the shipped toml.

5. Create and start the sidecar. Administrator PowerShell:

   ```powershell
   $config = "C:\ProgramData\AxialDB\mysql\axialdb.toml"
   $engine = "C:\Program Files\AxialDB\axialdb-engine.exe"
   sc.exe create AxialDBEngine binPath= "`"$engine`" --config `"$config`"" start= auto DisplayName= "AxialDB Analytics Engine"
   sc.exe config AxialDBEngine obj= LocalSystem
   sc.exe failure AxialDBEngine reset= 86400 actions= restart/60000/restart/60000/restart/60000
   Start-Service AxialDBEngine
   ```

   Confirm it is running: `Get-Service AxialDBEngine`.

6. Start MySQL.

7. Register the plugin and the helper functions once:

   ```sql
   INSTALL PLUGIN axialdb SONAME 'ha_axialdb.dll';
   ```

   Then run `install-axialdb-mysql-functions.sql` in the `mysql` database.

8. Check the link between MySQL and the sidecar:

   ```sql
   SELECT axialdb_init();
   ```

   You want a short success string, not a connection error. If this fails, the service is down or `AXIALDB_CONFIG` is wrong. MySQL must be restarted after that variable is set.

## First view

A snapshot is the right first test. It copies the query result once. It does not follow later changes until you create it again.

```sql
CREATE DATABASE IF NOT EXISTS demo_perf;
CREATE TABLE demo_perf.t ENGINE=AXIALDB AS
SELECT 1 AS id, 'hello' AS msg;
SELECT * FROM demo_perf.t;
```

For a real report, use the same shape over your own tables. `GROUP BY` belongs in the `SELECT` you run against the view, which is the fast path. The numbers we published are on [axialdb.com/measurements](https://axialdb.com/measurements.html).

## Live view (binlog)

Leave `[cdc] enabled = false` until the server settings above are true and this user exists:

```sql
CREATE USER 'axialdb_cdc'@'127.0.0.1' IDENTIFIED BY 'choose-a-password';
GRANT REPLICATION SLAVE, REPLICATION CLIENT, SELECT ON *.* TO 'axialdb_cdc'@'127.0.0.1';
```

Put that password in `C:\ProgramData\AxialDB\mysql\axialdb.toml`, set `enabled = true`, and restart **AxialDBEngine**. The port in the toml must be your MySQL port.

A live view is only for a narrow `CREATE` statement: one InnoDB table, or a fact table left-joined to its dimensions on the dimension primary key, plain source columns, primary keys included. If the statement is outside that list, `CREATE` fails. It does not silently make a snapshot. The full list is [cdc-limitations.md](cdc-limitations.md).

```sql
CREATE TABLE demo_perf.orders_av ENGINE=AXIALDB COMMENT='cdc' AS
SELECT id, customer_id, total
FROM demo_perf.orders;

SELECT axialdb_cdc_status('demo_perf', 'orders_av');
```

Wait until the status is `healthy` before you trust a `SELECT`. Source inserts, updates, and deletes then show up on their own, usually within a few seconds. `TRUNCATE` on the source requires you to recreate the view. Do not update a primary key on a source table that a live view watches: the new key is applied and the old key is left behind.

The fifth view is the last free one. The second live view is the last free live one. The next `CREATE` is refused. Nothing already created is dropped. A license file named `axialdb.lic`, placed beside `axialdb.toml`, raises those caps after you restart AxialDBEngine.

## If something fails

| What you see | What it usually means |
|--------------|------------------------|
| `axialdb_init()` cannot connect | AxialDBEngine is stopped, or MySQL was not restarted after `AXIALDB_CONFIG` was set |
| Error 126 loading the plugin | `axialdb_mysql_bridge.dll` is not in the plugin folder, or that folder is not on the Machine `PATH` |
| Error 1125, plugin `DELETED` | Another client still holds the old plugin. Disconnect it, or restart MySQL, then `INSTALL PLUGIN` again |
| Live `CREATE` fails immediately | The `SELECT` is outside [cdc-limitations.md](cdc-limitations.md), or `[cdc] enabled` is still false |
| Status stays `catching_up` | The sidecar is still applying the binlog. Reads fail closed until `healthy` |

Engine log: `C:\ProgramData\AxialDB\mysql\logs\axialdb-engine.log`.

## Remove it

```sql
DROP FUNCTION IF EXISTS axialdb_init;
DROP FUNCTION IF EXISTS axialdb_drop_view;
UNINSTALL PLUGIN axialdb;
```

Then `Stop-Service AxialDBEngine` and `sc.exe delete AxialDBEngine`. Delete the DLLs, the engine exe, and `C:\ProgramData\AxialDB\mysql` if you do not want the columnar files. Remove the Machine `AXIALDB_CONFIG` and the plugin folder from `PATH` if nothing else uses them.
