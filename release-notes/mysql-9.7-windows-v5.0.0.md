## AxialDB 5.0.0 - MySQL 9.7 Windows x64

**Artifact:** `axialdb-mysql-9.7-windows-x64-5.0.0.zip`  
**Build-ID:** `20260926-001`  
**SHA256:** `0faf30f2f4d1d288328a98e7d597793cda554f85220b0ef59d24a198ab17cbe7`  
**Released:** 2026-09-26

Free release. Five views, two of them live. It does not expire. [Terms of use](https://github.com/AxialDB/releases/blob/main/TERMS.md).

### Install

[Windows install guide](https://github.com/AxialDB/releases/blob/main/mysql/9.7/windows/README.md)

The zip contains the same guide, plus `TERMS.md` and `cdc-limitations.md`.

### Changes in 5.0.0

- **Free caps.** 5 views, 2 live. A license file beside `axialdb.toml` raises the caps.
- **Live views.** `COMMENT='cdc'` keeps a view current from the MySQL binlog. The `CREATE` subset is in [cdc-limitations.md](https://github.com/AxialDB/releases/blob/main/mysql/9.7/cdc-limitations.md). Outside that list, `CREATE` fails.
- **Status functions.** `axialdb_cdc_status` and `axialdb_cdc_publish`. Re-run `install-axialdb-mysql-functions.sql` after you replace the plugin.
- **Install paths** in the guide match the `axialdb.toml` in the zip. `[cdc] enabled` stays false until the replication user exists.

### Upgrade from 0.1.1

Stop MySQL and **AxialDBEngine**. Replace `ha_axialdb.dll`, `axialdb_mysql_bridge.dll`, and `axialdb-engine.exe`. Re-run the install SQL. If you already edited `axialdb.toml`, add the `[license]` and `[cdc]` sections from the zip instead of overwriting the file. Start **AxialDBEngine**, then MySQL.
