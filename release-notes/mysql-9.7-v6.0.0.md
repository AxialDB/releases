## AxialDB 6.0.0 - MySQL shim for MySQL 9.7

| Zip | Build-ID | SHA256 |
|-----|----------|--------|
| `axialdb-mysql-shim-6.0.0-9.7-windows-x64.zip` | `20261026-002` | `2685054360165cdc86e8d1c86d068d1143b982c2eda4ed637e9e516a1bfe146d` |
| `axialdb-mysql-shim-6.0.0-9.7-linux-x64.zip` | `20261026-002` | `46671c7f8eb78f1d946f3068454f1d2a387928de80a2dfcdefd0e81ef2d7e49e` |

**Released:** 2026-10-27

The AxialDB plugin for MySQL 9.7.0, 9.7.1, and 9.7.2, and its bridge: create and query AxialDB tables from inside MySQL with `CREATE TABLE ... ENGINE=AXIALDB` and ordinary `SELECT`. It needs the AxialDB engine of the same version, from the [`engine/v6.0.0`](https://github.com/AxialDB/releases/releases/tag/engine/v6.0.0) release. Free within the engine's caps: 5 tables, 2 of them live. [Terms of use](https://github.com/AxialDB/releases/blob/mysql/9.7/v6.0.0/TERMS.md).

### Install

Install the engine first, then: [Windows guide](https://github.com/AxialDB/releases/blob/mysql/9.7/v6.0.0/mysql/9.7/windows/README.md) · [Linux guide](https://github.com/AxialDB/releases/blob/mysql/9.7/v6.0.0/mysql/9.7/linux/README.md)

Requires a MySQL 9.7 server you run yourself. Managed services such as Amazon RDS and Aurora cannot load a storage-engine plugin. The plugin file must match the patch `SELECT VERSION()` reports; the zip has one for each of 9.7.0, 9.7.1, and 9.7.2.

### What is new in 6.0.0

- **The plugin has its own settings file**, `axialdb-shim.toml`: the engine's address and which of the engine's sources this server is. mysqld's `AXIALDB_CONFIG` names that file; the plugin no longer reads the engine's config. The engine can be on this machine or another one.
- **`system_time_zone`** (optional, in `axialdb-shim.toml`): the zone of a session left at `time_zone = SYSTEM`, MySQL's default. Unset, the plugin finds it as mysqld does, on Windows Server Core too. When it cannot, the statement fails and says to set the key; there is no silent default.
- **Live tables are `COMMENT='live'`** (and `COMMENT='live; schema=reporting'` for another schema). `COMMENT='cdc'` is refused. A live `CREATE` is checked by the engine, so the same query is accepted or refused in MySQL and on the command line. `ORDER BY` with `LIMIT` is new.
- **Refused on an AxialDB table**: `ALTER TABLE`, `RENAME TABLE`, `TRUNCATE TABLE`, a create onto a name that exists, and a `DROP TABLE` that names other tables too. Each message says what to do.
- **Replicas**: AxialDB's `CREATE` and `DROP` are not written to the binlog, and a replica does not need the plugin. `install-axialdb-mysql-functions.sql` turns the binlog off for its session; run it as an account that may set `sql_log_bin`.
- **Plugin and engine check each other's version** when the plugin connects, and a mismatch says which side is older. A 5.0.0 plugin cannot create live tables on the 6.0.0 engine.
- `axialdb_cdc_publish` is no longer installed.

### Upgrading from 5.0.0

There is no in-place upgrade. With 5.0.0 still installed, drop every AxialDB table in MySQL. Then follow the engine guide's "Upgrading from 5.0.0", install this plugin and `axialdb-shim.toml` by the guide, and create the tables again.
