# AxialDB for MySQL 9.7 — Windows x64 (MySQL shim package)

This package lets a MySQL server create and query AxialDB tables from inside MySQL, with `CREATE TABLE ... ENGINE=AXIALDB` and ordinary `SELECT`. It is the AxialDB plugin that MySQL loads, and a small bridge library beside it. The tables themselves live in the **AxialDB engine**, which comes in its own package: install that first, on this machine or on another one, and give this server a `[sources.<name>]` entry there with its accounts (the engine package's guide, "Connect a MySQL server").

Without this package the engine still makes tables from this server, with the `axialdb` command line; they are queried through the engine (the command line, ODBC, JDBC) and not from inside MySQL.

The download is free; the caps of the free version (5 tables, 2 of them live) are the engine's. Read [TERMS.md](TERMS.md) before you rely on it in production.

## What is in the zip

| File | What it is |
|------|------------|
| `ha_axialdb-<patch>-windows-x64.dll` | The plugin, one file for each MySQL 9.7 patch: `9.7.0`, `9.7.1`, `9.7.2` |
| `axialdb_mysql_bridge.dll` | The bridge the plugin loads |
| `axialdb-shim.toml` | This server's settings: where the engine is, and which source this server is |
| `install-axialdb-mysql-functions.sql` | The helper functions (`axialdb_init`, `axialdb_cdc_status`, `axialdb_drop_view`) |
| `TERMS.md`, `THIRD-PARTY-NOTICES.md`, `VERSION` | Terms, notices, and the build |

## What you need first

- MySQL Server **9.7**, 64-bit, with the default plugin folder. The plugin file must match the exact patch `SELECT VERSION()` reports.
- The AxialDB engine installed and running, with a `[sources.<name>]` entry for this server.
- An administrator PowerShell.

## Install

Stop MySQL first (`Stop-Service MySQL97`, or your service's name).

1. The plugin and the bridge, into MySQL's plugin folder. Pick the plugin for your patch:

   ```sql
   SELECT VERSION();
   ```

   ```powershell
   $Version = "9.7.2"   # the numeric part of SELECT VERSION()
   $plugin = "C:\Program Files\MySQL\MySQL Server 9.7\lib\plugin"
   Copy-Item ".\ha_axialdb-$Version-windows-x64.dll" "$plugin\ha_axialdb.dll"
   Copy-Item .\axialdb_mysql_bridge.dll "$plugin\"
   ```

   Do not rename the bridge. If there is no plugin file for your patch, this build does not support it. When you later move to another 9.7 patch, replace only `ha_axialdb.dll` with the file for the new patch and restart MySQL.

2. This server's settings:

   ```powershell
   New-Item -ItemType Directory -Force -Path C:\ProgramData\AxialDB\mysql | Out-Null
   Copy-Item .\axialdb-shim.toml C:\ProgramData\AxialDB\mysql\axialdb-shim.toml
   ```

   The file names the engine (`engine = "127.0.0.1:9742"` when it runs on this machine) and this server's source (`source = "mysql"`, the name of its `[sources.<name>]` entry in the engine's config). Change either to match. An engine on another machine also needs a secret and usually TLS: the engine package's `remote-engine.md`.

3. Two Machine environment variables, for the MySQL service:

   ```powershell
   [Environment]::SetEnvironmentVariable("AXIALDB_CONFIG", "C:\ProgramData\AxialDB", "Machine")
   $path = [Environment]::GetEnvironmentVariable("Path", "Machine")
   [Environment]::SetEnvironmentVariable("Path", "$plugin;$path", "Machine")
   ```

   `AXIALDB_CONFIG` is the install root; the plugin opens `mysql\axialdb-shim.toml` under it. The plugin folder on the `PATH` lets MySQL load the bridge. If the plugin still fails to load with error 126 after MySQL starts, reboot once so the service sees the new `PATH`.

4. Start MySQL, and register the plugin and the helper functions once:

   ```sql
   INSTALL PLUGIN axialdb SONAME 'ha_axialdb.dll';
   ```

   Then run `install-axialdb-mysql-functions.sql` in the `mysql` database. The script keeps its statements out of the binlog, so a replica without the plugin is not stopped by them; run it as an account that may set `sql_log_bin`.

5. Check the link:

   ```sql
   SELECT axialdb_init();
   ```

   It connects to the engine and says which source this server is. An error names what is wrong: the engine cannot be reached, or `source` is not a source of the engine.

## First tables

A snapshot copies the query's result once:

```sql
CREATE DATABASE IF NOT EXISTS demo;
CREATE TABLE demo.t ENGINE=AXIALDB AS SELECT 1 AS id, 'hello' AS msg;
SELECT * FROM demo.t;
```

A live table follows its source tables. It needs the two accounts of this server's source in the engine's config (`user` and `capture_user`) and a row-based binlog; the engine package's guide has both. What its query may contain is in the engine package's `live-tables.md`.

```sql
CREATE TABLE your_db.orders_av ENGINE=AXIALDB COMMENT='live' AS
SELECT id, customer_id, created_at, total FROM your_db.orders;

SELECT axialdb_cdc_status('your_db', 'orders_av');   -- wait for healthy
SELECT customer_id, SUM(total) FROM your_db.orders_av GROUP BY customer_id;
```

`COMMENT='live; schema=reporting'` puts the AxialDB table into another schema of the engine. `DROP TABLE your_db.orders_av` removes both the MySQL table and the engine's. `GROUP BY` belongs in the queries you run on the table, which the engine answers.

A table created here is also a table of the engine: the command line, ODBC, and JDBC query it under its AxialDB name, and one query there can join it with tables from other sources.

## If something fails

| What you see | What it usually means |
|--------------|------------------------|
| `axialdb_init()` cannot connect | The engine is stopped, or MySQL was not restarted after `AXIALDB_CONFIG` was set, or `engine` in `axialdb-shim.toml` is wrong |
| Error 126 loading the plugin | `axialdb_mysql_bridge.dll` is not in the plugin folder, or that folder is not on the Machine `PATH` |
| Error 1125, plugin `DELETED` | Another client still holds the old plugin. Disconnect it, or restart MySQL, then `INSTALL PLUGIN` again |
| A live `CREATE` fails at once | The query is outside `live-tables.md`, or `user` or `capture_user` of this server's source is empty in the engine's config. The error says which |
| `AxialDB cannot tell which zone that is on this server` | The session is in `time_zone = SYSTEM` and Windows' zone could not be named. Set `system_time_zone` in `axialdb-shim.toml` to the zone's name, such as `"America/Toronto"` |
| The table stays `catching_up` | The engine is still applying the changes since the first copy. Queries are refused until it is `healthy` |
| The table shows old data, status `updating N% of a change of R rows` | A large change to its source is being applied. Queries answer from the table as it was until the change is applied whole |

## Remove it

```sql
SET sql_log_bin = 0;   -- a replica has no AxialDB functions to drop
DROP FUNCTION IF EXISTS axialdb_init;
DROP FUNCTION IF EXISTS axialdb_drop_view;
DROP FUNCTION IF EXISTS axialdb_cdc_publish;
DROP FUNCTION IF EXISTS axialdb_cdc_status;
UNINSTALL PLUGIN axialdb;
```

Drop the AxialDB tables first (`DROP TABLE` of each). Then remove the two files from the plugin folder and `C:\ProgramData\AxialDB\mysql\axialdb-shim.toml`, and restart MySQL.
