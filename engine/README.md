# AxialDB engine

The engine package: the engine, the `axialdb` command line, and the ODBC and JDBC drivers. One engine makes tables from MySQL 9.7 servers and MongoDB 8.0+ replica sets and answers queries over them. The current release is 6.0.0, attached to the [`engine/v6.0.0`](https://github.com/AxialDB/releases/releases/tag/engine/v6.0.0) release.

Each folder holds the documents of that system's zip, as they are in the zip.

| Doc | Windows x64 | Linux x64 |
|-----|-------------|-----------|
| Install guide, first tables, upgrading from 5.0.0 | [windows/README.md](windows/README.md) | [linux/README.md](linux/README.md) |
| The engine's config | [windows/axialdb.toml](windows/axialdb.toml) | [linux/axialdb.toml](linux/axialdb.toml) |
| What a live table can be | [windows/live-tables.md](windows/live-tables.md) | [linux/live-tables.md](linux/live-tables.md) |
| The engine on a machine of its own | [windows/remote-engine.md](windows/remote-engine.md) | [linux/remote-engine.md](linux/remote-engine.md) |
| ODBC driver: Tableau, Power BI, Excel | [windows/odbc/README.md](windows/odbc/README.md) | [linux/odbc/README.md](linux/odbc/README.md) |
| JDBC driver: DBeaver | [windows/jdbc/README.md](windows/jdbc/README.md) | [linux/jdbc/README.md](linux/jdbc/README.md) |
| Terms and notices | [windows/TERMS.md](windows/TERMS.md), [windows/THIRD-PARTY-NOTICES.md](windows/THIRD-PARTY-NOTICES.md) | [linux/TERMS.md](linux/TERMS.md), [linux/THIRD-PARTY-NOTICES.md](linux/THIRD-PARTY-NOTICES.md) |

To create and query AxialDB tables from inside MySQL as well, add the MySQL shim package: [../mysql/9.7/](../mysql/9.7/).
