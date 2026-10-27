## AxialDB 5.0.0 - MySQL 9.7 Linux x64

> Superseded by 6.0.0: [engine](https://github.com/AxialDB/releases/releases/tag/engine/v6.0.0) and [MySQL shim](https://github.com/AxialDB/releases/releases/tag/mysql/9.7/v6.0.0). The links below point to this repository as it was for 5.0.0.

**Artifact:** `axialdb-mysql-9.7-linux-x64-5.0.0.zip`  
**Build-ID:** `20260927-004`  
**SHA256:** `294b01d4a71bf791f14e9bd2f40bfe5bf7eec41f4e4d0bdca0ad263f85678aaf`  
**Released:** 2026-09-27

Free release. Five views, two of them live. It does not expire. [Terms of use](https://github.com/AxialDB/releases/blob/bf11571bd7c7fdcbcc72247d51c5f8824916fc06/TERMS.md).

### Install

[Linux install guide](https://github.com/AxialDB/releases/blob/bf11571bd7c7fdcbcc72247d51c5f8824916fc06/mysql/9.7/linux/README.md)

The zip attached to this release has the engine, `libaxialdb_mysql_bridge.so`, the systemd unit, and the MySQL 9.7.0 plugin. The same plugin and bridge are in the repository, in [mysql/9.7/linux](https://github.com/AxialDB/releases/tree/bf11571bd7c7fdcbcc72247d51c5f8824916fc06/mysql/9.7/linux): `ha_axialdb-<version>-linux-x64.so` and `libaxialdb_mysql_bridge.so`. A plugin for a later 9.7 patch is added there. The [install guide](https://github.com/AxialDB/releases/blob/bf11571bd7c7fdcbcc72247d51c5f8824916fc06/mysql/9.7/linux/README.md) says how to match the plugin to `SELECT VERSION()` and copy it as `ha_axialdb.so`.

Requires Linux x86_64 with glibc 2.35 or newer, and a MySQL 9.7 server you run yourself. Managed services such as Amazon RDS and Aurora cannot load a storage-engine plugin.

### Changes in 5.0.0

Same engine version and source as the Windows 5.0.0 zip.

- **Free caps.** 5 views, 2 live. A license file beside `axialdb.toml` raises the caps.
- **Live views** from the MySQL binlog, on the subset in [cdc-limitations.md](https://github.com/AxialDB/releases/blob/bf11571bd7c7fdcbcc72247d51c5f8824916fc06/mysql/9.7/cdc-limitations.md).
- **Status functions.** `axialdb_cdc_status` and `axialdb_cdc_publish`. Re-run `install-axialdb-mysql-functions.sql` after you replace the plugin.
- The shipped unit file is `axialdb-engine.service`.

### If you already installed 0.1.x

Remove the old plugin, unit, and engine, then install this zip on the paths in the guide and create the views again. Do not reuse an old config whose paths differ.
