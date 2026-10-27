## AxialDB 6.0.0 - engine

| Zip | Build-ID | SHA256 |
|-----|----------|--------|
| `axialdb-engine-6.0.0-windows-x64.zip` | `20261027-001` | `e22612282512129aa22dd8bdcb055988f3162f28430fd800849151aaa136fde7` |
| `axialdb-engine-6.0.0-linux-x64.zip` | `20261027-001` | `f9daf76b5d0d43994ff21eea657fe0d89d8a3154b41e5215ad890443126fb3b7` |

**Released:** 2026-10-27

Free for 5 tables, 2 of them live. It does not expire. [Terms of use](https://github.com/AxialDB/releases/blob/8c4ef7b930edb111a6a64ab5b37f06a9d1c9fe4d/TERMS.md).

### Install

[Windows install guide](https://github.com/AxialDB/releases/blob/8c4ef7b930edb111a6a64ab5b37f06a9d1c9fe4d/engine/windows/README.md) · [Linux install guide](https://github.com/AxialDB/releases/blob/8c4ef7b930edb111a6a64ab5b37f06a9d1c9fe4d/engine/linux/README.md)

To create and query AxialDB tables from inside MySQL as well, add the MySQL shim package of the same version: [`mysql/9.7/v6.0.0`](https://github.com/AxialDB/releases/releases/tag/mysql/9.7/v6.0.0).

### What is new in 6.0.0

- **Two packages.** This engine package works on its own: the engine, the `axialdb` command line, and the ODBC and JDBC drivers. The MySQL plugin is a separate, optional package.
- **One engine, several sources.** Each MySQL 9.7 server and each MongoDB 8.0+ replica set is a `[sources.<name>]` entry in `axialdb.toml`, and one query can join tables from all of them. MongoDB is new in this release.
- **The `axialdb` command line**: `sources`, `tables`, `create-table`, `drop-table`, `query`, `export-tables`, `create-tables`.
- **Live tables** follow the MySQL binlog or the MongoDB change stream. What a live table can be: [live-tables.md](https://github.com/AxialDB/releases/blob/8c4ef7b930edb111a6a64ab5b37f06a9d1c9fe4d/engine/linux/live-tables.md). A live table shows `stale since <time>` while its source cannot be reached and `failed` with the reason when it has to be created again; `axialdb.sources` shows each source's state.
- **Column types are kept.** A MySQL `DATE` is a date, `DATETIME` and `TIMESTAMP` are timestamps (held in UTC), `DECIMAL` is exact, `TINYINT(1)` is a boolean. Reporting tools get these types where they got text before.
- **Reporting tools.** The ODBC driver works with Tableau (with the customization file in the zip), Power BI, Excel, and .NET programs; the JDBC driver with DBeaver. Rows arrive as they are fetched, and closing a result early stops the query. `DbIdentity` is optional: without it a connection sees every schema.
- **The engine on another machine**, with a client secret and TLS: [remote-engine.md](https://github.com/AxialDB/releases/blob/8c4ef7b930edb111a6a64ab5b37f06a9d1c9fe4d/engine/linux/remote-engine.md). One engine can serve several MySQL servers.
- **Limits that protect the engine** under `[engine]`: the memory all queries may hold, joins that would compare every row with every row, the longest a query may run, and how many queries run at once. A query that hits one fails with a message naming the setting; the engine and the other queries go on.
- **The free caps count tables**: 5 tables, 2 of them live. A license file lifts them.

### Upgrading from 5.0.0

There is no in-place upgrade. Tables made by 5.0.0 are not read: drop them with 5.0.0 still installed, install 6.0.0, write the new config from the one in the zip, and create the tables again. The steps are in the install guide, "Upgrading from 5.0.0". ODBC and JDBC connections and workbooks that named the schema `mysql_<database>` now name `<database>`.
