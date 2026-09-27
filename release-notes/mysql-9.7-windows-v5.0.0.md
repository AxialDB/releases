## AxialDB 5.0.0 - MySQL 9.7 Windows x64

**Artifact:** `axialdb-mysql-9.7-windows-x64-5.0.0.zip`  
**Build-ID:** `20260927-002`  
**SHA256:** `c94682f8dedf964bc7c7234c12d8e3431a43c7a0e4669562e408676275f31334`  
**Released:** 2026-09-27

Free release. Five views, two of them live. It does not expire. [Terms of use](https://github.com/AxialDB/releases/blob/main/TERMS.md).

### Install

[Windows install guide](https://github.com/AxialDB/releases/blob/main/mysql/9.7/windows/README.md)

The engine zip is attached to this release. The MySQL plugin and the bridge are in the repository, in [mysql/9.7/windows](https://github.com/AxialDB/releases/tree/main/mysql/9.7/windows): `ha_axialdb-<version>-windows-x64.dll` and `axialdb_mysql_bridge.dll`. The [install guide](https://github.com/AxialDB/releases/blob/main/mysql/9.7/windows/README.md) says how to match the plugin to `SELECT VERSION()` and copy it as `ha_axialdb.dll`.

### Changes in 5.0.0

- **Free caps.** 5 views, 2 live. A license file beside `axialdb.toml` raises the caps.
- **Live views.** `COMMENT='cdc'` keeps a view current from the MySQL binlog. The `CREATE` subset is in [cdc-limitations.md](https://github.com/AxialDB/releases/blob/main/mysql/9.7/cdc-limitations.md). Outside that list, `CREATE` fails.
- **Status functions.** `axialdb_cdc_status` and `axialdb_cdc_publish`. Re-run `install-axialdb-mysql-functions.sql` after you replace the plugin.
- **Install paths** in the guide match the `axialdb.toml` in the zip. `[cdc] enabled` stays false until the replication user exists.

### If you already installed 0.1.x

Those builds used different paths. Do not point this release at the old config or data directory. Remove the old plugin and service, install this zip on the paths in the guide, and create the views again.
