## AxialDB 5.0.0 - MySQL 9.7 Linux x64

**Artifact:** `axialdb-mysql-9.7-linux-x64-5.0.0.zip`  
**Build-ID:** `20260926-001`  
**SHA256:** `6dfcba8e59858fd8e8f4aa2904577c084a26f9f7c7e1f97df54fa3e20b750d66`  
**Released:** 2026-09-26  
**GitHub Release:** [mysql/9.7/linux/v5.0.0](https://github.com/AxialDB/releases/releases/tag/mysql/9.7/linux/v5.0.0)

Free release. Five views, two of them live. It does not expire. See [TERMS.md](../TERMS.md). Versions 0.1.0 and 0.1.1 remain evaluation builds under [EVALUATION_LICENSE.md](../EVALUATION_LICENSE.md).

### Install

[mysql/9.7/linux/README.md](../mysql/9.7/linux/README.md)

The zip contains the same guide, `axialdb-engine.service`, `TERMS.md`, and `cdc-limitations.md`.

### Changes in 5.0.0

Same engine as the Windows 5.0.0 zip.

- **Free caps.** 5 views, 2 live. A license file beside `axialdb.toml` raises the caps.
- **Live views** from the MySQL binlog, on the subset in `cdc-limitations.md`.
- **Status functions.** `axialdb_cdc_status` and `axialdb_cdc_publish`. Re-run `install-axialdb-mysql-functions.sql` after you replace the plugin.
- The shipped unit file is `axialdb-engine.service`.

### Upgrade from 0.1.1

Stop MySQL and `axialdb-engine`. Replace `ha_axialdb.so`, `libaxialdb_mysql_bridge.so`, and `/usr/local/axialdb/axialdb-engine`. Re-run the install SQL. If you already edited `/etc/axialdb/axialdb.toml`, add the `[license]` and `[cdc]` sections from the zip instead of overwriting the file. Start the engine, then MySQL.
