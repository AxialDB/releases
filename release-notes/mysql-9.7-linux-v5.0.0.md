## AxialDB 5.0.0 - MySQL 9.7 Linux x64

**Artifact:** `axialdb-mysql-9.7-linux-x64-5.0.0.zip`  
**Build-ID:** `20260927-003`  
**SHA256:** `fb4910d2f0fe9dbcd11a6d6f12b8f9a3faef7f9ec0f860c14efb73777f7258b6`  
**Released:** 2026-09-27

Free release. Five views, two of them live. It does not expire. [Terms of use](https://github.com/AxialDB/releases/blob/main/TERMS.md).

### Install

[Linux install guide](https://github.com/AxialDB/releases/blob/main/mysql/9.7/linux/README.md)

The engine zip is attached to this release. The MySQL plugin and the bridge are in the repository, in [mysql/9.7/linux](https://github.com/AxialDB/releases/tree/main/mysql/9.7/linux): `ha_axialdb-<version>-linux-x64.so` and `libaxialdb_mysql_bridge.so`. The [install guide](https://github.com/AxialDB/releases/blob/main/mysql/9.7/linux/README.md) says how to match the plugin to `SELECT VERSION()` and copy it as `ha_axialdb.so`. Linux x86_64 needs glibc 2.35 or newer.

### Changes in 5.0.0

Same engine as the Windows 5.0.0 zip.

- **Free caps.** 5 views, 2 live. A license file beside `axialdb.toml` raises the caps.
- **Live views** from the MySQL binlog, on the subset in [cdc-limitations.md](https://github.com/AxialDB/releases/blob/main/mysql/9.7/cdc-limitations.md).
- **Status functions.** `axialdb_cdc_status` and `axialdb_cdc_publish`. Re-run `install-axialdb-mysql-functions.sql` after you replace the plugin.
- The shipped unit file is `axialdb-engine.service`.

### If you already installed 0.1.x

Remove the old plugin, unit, and engine, then install this zip on the paths in the guide and create the views again. Do not reuse an old config whose paths differ.
