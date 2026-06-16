# AxialDB for MySQL 9.7 - Windows x64 eval

Pre-release eval only. See [EVALUATION_LICENSE.md](../../../EVALUATION_LICENSE.md) and the [GitHub Release](https://github.com/AxialDB/releases/releases) for this version.

AxialDB adds an **AXIALDB** storage engine and a **sidecar** process (`axialdb-engine.exe`). **mysqld does not start the sidecar** (`helper.auto_spawn = false`). You must run **AxialDBEngine** as a Windows service before `axialdb_init()` or CTAS.

## Zip contents

| File | Purpose |
|------|---------|
| `ha_axialdb.dll` | Storage engine plugin |
| `axialdb_mysql_bridge.dll` | Bridge (same folder as plugin) |
| `axialdb-engine.exe` | Sidecar analytics engine |
| `axialdb.toml` | Example config (copy elsewhere; edit paths) |
| `install-axialdb-mysql-functions.sql` | UDF registration |
| `VERSION` | Build-ID for support |
| `README.md` | This file |

## Default paths (match `axialdb.toml`)

| Item | Path |
|------|------|
| Plugins | `C:\Program Files\MySQL\MySQL Server 9.7\lib\plugin\` |
| Engine | `C:\Program Files\AxialDB\axialdb-engine.exe` |
| Config | `C:\ProgramData\AxialDB\axialdb.toml` |
| Data / catalog | `C:\ProgramData\AxialDB\data\` |
| Engine log | `C:\ProgramData\AxialDB\logs\axialdb-engine.log` |
| Sidecar service | **AxialDBEngine** (Windows SCM) |
| MySQL datadir (optional) | `C:\ProgramData\MySQL\MySQL Server 9.7\Data` — janitor only; see below |

## Config (`axialdb.toml`)

Copy to a permanent path; set **`AXIALDB_CONFIG`** to that file for **mysqld** and the sidecar.

| Setting | Default | Notes |
|---------|---------|--------|
| `data.axialdb_data_dir` | `C:/ProgramData/AxialDB/data` | Parquet + `catalog.db` |
| `data.mysql_datadir` | `C:/ProgramData/MySQL/MySQL Server 9.7/Data` | **Optional.** Janitor-only: read-only check for `{schema}/{table}.sdi` under MySQL `@@datadir`. Removes stale **published** catalog rows when the MySQL table is gone. Omit the key (or unset **`AXIALDB_MYSQL_DATADIR`** on the engine) to skip. Does not affect CTAS or queries. |
| `helper.executable` | `C:/Program Files/AxialDB/axialdb-engine.exe` | Must match SCM `binPath` |
| `helper.service_name` | `AxialDBEngine` | Windows SCM name |
| `helper.auto_spawn` | `false` | Sidecar via SCM, not mysqld |
| `logging.file` | `C:/ProgramData/AxialDB/logs/axialdb-engine.log` | Engine log |

Confirm MySQL datadir: `SELECT @@datadir;` in `mysql` and align `mysql_datadir` (forward slashes in TOML).

## Prerequisites

- MySQL Server **9.7** x64, default `plugin_dir` (no custom `plugin_dir` in `my.ini`).
- Administrator rights for file copy, Machine env, and `sc.exe`.
- MySQL service account must **write** to `axialdb_data_dir` and the log file.

## Install (from zip)

1. **Stop MySQL** (e.g. `Stop-Service MySQL97`).

2. **Plugins** — copy both DLLs to `C:\Program Files\MySQL\MySQL Server 9.7\lib\plugin\`.

3. **Engine** — create `C:\Program Files\AxialDB\`, copy `axialdb-engine.exe` there.

4. **Config** — create `C:\ProgramData\AxialDB\data` and `\logs`. Copy `axialdb.toml` to `C:\ProgramData\AxialDB\axialdb.toml`. Edit paths if you changed step 3.

5. **Machine environment** (required for **mysqld**):
   - `AXIALDB_CONFIG` = `C:\ProgramData\AxialDB\axialdb.toml` (Machine scope).
   - Prepend `C:\Program Files\MySQL\MySQL Server 9.7\lib\plugin` to Machine **PATH** (loads `axialdb_mysql_bridge.dll`; error 126 if missing).

6. **Sidecar service** — Administrator PowerShell (paths must match your config):

   ```powershell
   $config = "C:\ProgramData\AxialDB\axialdb.toml"
   $engine = "C:\Program Files\AxialDB\axialdb-engine.exe"
   sc.exe create AxialDBEngine binPath= "`"$engine`" --config `"$config`"" start= auto DisplayName= "AxialDB Analytics Engine"
   sc.exe config AxialDBEngine obj= LocalSystem
   sc.exe failure AxialDBEngine reset= 86400 actions= restart/60000/restart/60000/restart/60000
   Start-Service AxialDBEngine
   ```

   If upgrading from an older drop that used **Task Scheduler** for `AxialDBEngine`, unregister that task first.

7. **Start MySQL**.

8. **Plugin + UDFs** (once per server):

   ```sql
   INSTALL PLUGIN axialdb SONAME 'ha_axialdb.dll';
   ```

   Then run `install-axialdb-mysql-functions.sql`.

9. **Verify** (sidecar must be running):

   ```sql
   SELECT axialdb_init();
   ```

## Uninstall

```sql
DROP FUNCTION IF EXISTS axialdb_init;
DROP FUNCTION IF EXISTS axialdb_drop_view;
UNINSTALL PLUGIN axialdb;
```

Stop and remove the service: `Stop-Service AxialDBEngine; sc.exe delete AxialDBEngine`. Remove DLLs, engine, config, and revert Machine `AXIALDB_CONFIG` / `PATH` if unused.

Error **1125** on reinstall: close other MySQL clients or restart MySQL.

## Git clone / eval dev (optional)

Repo scripts use **ProgramData** engine path (`C:\ProgramData\AxialDB\bin\`) and install SCM via:

`.\scripts\mysql\configure-mysql-eval-layout.ps1` (elevated), then `redeploy-mysql-eval.ps1 -BuildHelper`.

That layout matches release behavior (SCM sidecar, `auto_spawn = false`); only install paths differ.
