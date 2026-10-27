# AxialDB for MySQL 9.7 (MySQL shim package)

The MySQL shim package: the AxialDB plugin for MySQL 9.7.0, 9.7.1, and 9.7.2 and its bridge, which let a MySQL server create and query AxialDB tables from inside MySQL. The tables live in the AxialDB engine, which comes in its own package: install that first ([../../engine/](../../engine/)). The current release is 6.0.0, attached to the [`mysql/9.7/v6.0.0`](https://github.com/AxialDB/releases/releases/tag/mysql/9.7/v6.0.0) release.

Each folder holds the documents of that system's zip, as they are in the zip.

| Doc | Windows x64 | Linux x64 |
|-----|-------------|-----------|
| Install the plugin, point it at the engine, first tables | [windows/README.md](windows/README.md) | [linux/README.md](linux/README.md) |
| This server's settings | [windows/axialdb-shim.toml](windows/axialdb-shim.toml) | [linux/axialdb-shim.toml](linux/axialdb-shim.toml) |
| The helper functions | [windows/install-axialdb-mysql-functions.sql](windows/install-axialdb-mysql-functions.sql) | [linux/install-axialdb-mysql-functions.sql](linux/install-axialdb-mysql-functions.sql) |
| Terms and notices | [windows/TERMS.md](windows/TERMS.md), [windows/THIRD-PARTY-NOTICES.md](windows/THIRD-PARTY-NOTICES.md) | [linux/TERMS.md](linux/TERMS.md), [linux/THIRD-PARTY-NOTICES.md](linux/THIRD-PARTY-NOTICES.md) |

What a live table can be is in the engine package: [live-tables.md](../../engine/linux/live-tables.md).

The plugins of 5.0.0 are no longer in this folder; they do not work with the 6.0.0 engine. The 5.0.0 files, with the plugins for 9.7.0, 9.7.1, and 9.7.2, stay in this repository's history: [mysql/9.7 as of 5.0.0](https://github.com/AxialDB/releases/tree/bf11571bd7c7fdcbcc72247d51c5f8824916fc06/mysql/9.7).
