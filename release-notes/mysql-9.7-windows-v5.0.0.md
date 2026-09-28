## AxialDB 5.0.0 - MySQL 9.7 Windows x64

**Artifact:** `axialdb-mysql-9.7-windows-x64-5.0.0.zip`  
**Build-ID:** `20260927-006`  
**SHA256:** `5c65f7ea68b9bbe58403b8b68536f6cf80dbd435adfd973e64fc23ba275f95f0`  
**Released:** 2026-09-27

Free release. Five views, two of them live. It does not expire. [Terms of use](https://github.com/AxialDB/releases/blob/main/TERMS.md).

### Install

[Windows install guide](https://github.com/AxialDB/releases/blob/main/mysql/9.7/windows/README.md)

The zip attached to this release has the engine, `axialdb_mysql_bridge.dll`, and the MySQL 9.7.0 plugin. The same plugin and bridge are in the repository, in [mysql/9.7/windows](https://github.com/AxialDB/releases/tree/main/mysql/9.7/windows): `ha_axialdb-<version>-windows-x64.dll` and `axialdb_mysql_bridge.dll`. A plugin for a later 9.7 patch is added there. The [install guide](https://github.com/AxialDB/releases/blob/main/mysql/9.7/windows/README.md) says how to match the plugin to `SELECT VERSION()` and copy it as `ha_axialdb.dll`.

Requires a MySQL 9.7 server you run yourself. Managed services such as Amazon RDS and Aurora cannot load a storage-engine plugin.

### Changes in 5.0.0

- **Free caps.** 5 views, 2 live. A license file beside `axialdb.toml` raises the caps.
- **Live views.** `COMMENT='cdc'` keeps a view current from the MySQL binlog. The `CREATE` subset is in [cdc-limitations.md](https://github.com/AxialDB/releases/blob/main/mysql/9.7/cdc-limitations.md). Outside that list, `CREATE` fails.
- **Status functions.** `axialdb_cdc_status` and `axialdb_cdc_publish`. Re-run `install-axialdb-mysql-functions.sql` after you replace the plugin.
- **Install paths** in the guide match the `axialdb.toml` in the zip. `[cdc] enabled` stays false until the replication user exists.

### If you already installed 0.1.x

Those builds used different paths. Do not point this release at the old config or data directory. Remove the old plugin and service, install this zip on the paths in the guide, and create the views again.
