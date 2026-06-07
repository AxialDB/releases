# AxialDB for MySQL 9.7 - Windows x64 eval

Self-managed **MySQL Community 9.7** (x64) with AxialDB storage engine and sidecar.

Pre-release eval only. See [EVALUATION_LICENSE.md](../../../EVALUATION_LICENSE.md) and the [GitHub Release](https://github.com/AxialDB/releases/releases) for this version.

## Zip contents

| File | Purpose |
|------|---------|
| `ha_axialdb.dll` | AxialDB storage engine plugin |
| `axialdb_mysql_bridge.dll` | Bridge library (same folder as engine plugin) |
| `axialdb-engine.exe` | Sidecar analytics engine |
| `axialdb.toml` | **Example config** with default paths (edit before use) |
| `install-axialdb-mysql-functions.sql` | UDF registration SQL |
| `VERSION` | Release identity and Build-ID (for support) |
| `README.md` | This file |

## Config (`axialdb.toml`)

**This file is an example with default values.** Copy it to a permanent location (for example `C:\ProgramData\AxialDB\axialdb.toml`), edit paths and settings for your environment, and point `AXIALDB_CONFIG` at that file. Do not use the copy inside the zip extract folder unless your layout matches the defaults exactly.

Typical fields to review:

| Setting | Default | Change if... |
|---------|---------|--------------|
| `data.axialdb_data_dir` | `C:/ProgramData/AxialDB/data` | Data should live elsewhere |
| `helper.executable` | `C:/Program Files/AxialDB/axialdb-engine.exe` | Engine installed elsewhere |
| `logging.file` | `C:/ProgramData/AxialDB/logs/axialdb-engine.log` | Logs should go elsewhere |

## Prerequisites

- MySQL Server **9.7** x64, default `plugin_dir` (do not override `plugin_dir` in `my.ini`).
- Administrator rights to copy files and set machine environment variables.
- Port **3306** (or adjust your client accordingly).

## Install

1. **Stop MySQL** (service name depends on your install, e.g. `MySQL97`).

2. **Copy plugins** to MySQL default plugin folder (both DLLs):
   `C:\Program Files\MySQL\MySQL Server 9.7\lib\plugin\`

3. **Copy engine** to:
   `C:\Program Files\AxialDB\axialdb-engine.exe`

4. **Config** - copy `axialdb.toml` to e.g. `C:\ProgramData\AxialDB\axialdb.toml`, edit paths, create `data` and `logs` directories referenced in the file.

5. **Machine environment** (required):
   - Set `AXIALDB_CONFIG` to the **absolute path** of your installed `axialdb.toml` (Machine scope for the MySQL service account).
   - Prepend `C:\Program Files\MySQL\MySQL Server 9.7\lib\plugin` to Machine `PATH`. Without this, `mysqld` may fail to load `axialdb_mysql_bridge.dll` (Windows error 126).

6. **Start sidecar** - `axialdb-engine.exe` is a console process, not a Windows service. Start it manually and keep it running, for example:
   `"C:\Program Files\AxialDB\axialdb-engine.exe" --config "C:\ProgramData\AxialDB\axialdb.toml"`
   You may register your own scheduled task or service if desired.

7. **Start MySQL**.

8. **Register plugin and UDFs** (once per server, in `mysql` CLI or DBeaver):
   ```sql
   INSTALL PLUGIN axialdb SONAME 'ha_axialdb.dll';
   ```
   Then run `install-axialdb-mysql-functions.sql`.

9. **Verify**:
   ```sql
   SELECT axialdb_init();
   ```

## Data location

- Parquet and `catalog.db`: under `axialdb_data_dir` in your config (default `C:\ProgramData\AxialDB\data\`).
- Engine log: path in `logging.file` in your config.

## Uninstall

```sql
UNINSTALL PLUGIN axialdb;
```

Stop `axialdb-engine`, remove DLLs and installed files, revert `AXIALDB_CONFIG` and `PATH` if no longer needed.
