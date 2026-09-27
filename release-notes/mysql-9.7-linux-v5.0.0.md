## AxialDB 5.0.0 - MySQL 9.7 Linux x64

**Artifact:** `axialdb-mysql-9.7-linux-x64-5.0.0.zip`  
**Build-ID:** `20260926-001`  
**SHA256:** `6dfcba8e59858fd8e8f4aa2904577c084a26f9f7c7e1f97df54fa3e20b750d66`  
**Released:** 2026-09-26

Free release. Five views, two of them live. It does not expire. [Terms of use](https://github.com/AxialDB/releases/blob/main/TERMS.md).

### Install

[Linux install guide](https://github.com/AxialDB/releases/blob/main/mysql/9.7/linux/README.md)

The zip contains the engine, the bridge, `axialdb-engine.service`, `TERMS.md`, and `cdc-limitations.md`. The MySQL plugin is a separate file on this release: `ha_axialdb-<version>-linux-x64.so`. The [install guide](https://github.com/AxialDB/releases/blob/main/mysql/9.7/linux/README.md) says how to match it to `SELECT VERSION()` and copy it as `ha_axialdb.so`. Linux x86_64 needs glibc 2.35 or newer.

### Changes in 5.0.0

Same engine as the Windows 5.0.0 zip.

- **Free caps.** 5 views, 2 live. A license file beside `axialdb.toml` raises the caps.
- **Live views** from the MySQL binlog, on the subset in [cdc-limitations.md](https://github.com/AxialDB/releases/blob/main/mysql/9.7/cdc-limitations.md).
- **Status functions.** `axialdb_cdc_status` and `axialdb_cdc_publish`. Re-run `install-axialdb-mysql-functions.sql` after you replace the plugin.
- The shipped unit file is `axialdb-engine.service`.

### If you already installed 0.1.x

Remove the old plugin, unit, and engine, then install this zip on the paths in the guide and create the views again. Do not reuse an old config whose paths differ.
