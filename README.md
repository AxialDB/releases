# AxialDB downloads

Prebuilt AxialDB. This repository has no source code. The analytical engine is private. The MySQL binlog and MongoDB change-stream reader it uses, [ce-stream](https://github.com/AxialDB/ce-stream), is a separate open-source project.

Website: [axialdb.com](https://axialdb.com/).

AxialDB keeps a columnar copy of the tables your reports use and answers the heavy queries from that copy. One engine reads MySQL servers and MongoDB replica sets, and one query can join tables from several of them. Your databases stay the system of record; AxialDB does not write to them.

## Free version

The download is free to run within a cap: **5 tables**, and **2 of those may be live** (kept current from the database's change log). It does not expire. It is the same engine a paid license unlocks. The license file lifts the caps and is how a support agreement is made. It does not add a second product.

Read the [terms of use](TERMS.md) before you install. The free version is provided as-is. There is no warranty and no support agreement. You are responsible for backups and for where you run it. We test each release, including live tables under load, and AxialDB does not write to your databases. That is not a promise that nothing on your server can go wrong.

The current release is **6.0.0**.

## Install

A release has two packages for each system. Start with the engine.

| Package | What it is | Windows x64 | Linux x64 |
|---------|------------|-------------|-----------|
| **Engine** | The engine, the `axialdb` command line, the ODBC and JDBC drivers. Makes tables from MySQL 9.7 and MongoDB 8.0+ and answers queries | [engine/windows/README.md](engine/windows/README.md) | [engine/linux/README.md](engine/linux/README.md) |
| **MySQL shim** | Optional. The plugin for MySQL 9.7.0, 9.7.1, and 9.7.2 and its bridge, to create and query AxialDB tables from inside MySQL | [mysql/9.7/windows/README.md](mysql/9.7/windows/README.md) | [mysql/9.7/linux/README.md](mysql/9.7/linux/README.md) |

The zips are attached to [GitHub Releases](https://github.com/AxialDB/releases/releases): the engine to the `engine/v<version>` release, the MySQL shim to the `mysql/9.7/v<version>` release. Linux needs x86_64 with glibc 2.35 or newer.

The MySQL shim needs a MySQL 9.7 server you run yourself. Managed services such as Amazon RDS and Aurora cannot load a storage-engine plugin.

Coming from 5.0.0: the engine guide's "Upgrading from 5.0.0" says what to do. Tables of 5.0.0 are created again.

Published builds: [RELEASES.md](RELEASES.md).

## Paid use

More than 5 tables, more than 2 live tables, or a support agreement: info@axialdb.com. You receive `axialdb.lic`, place it beside the engine's `axialdb.toml`, and restart the engine.

Copyright (c) 2026 IT ART Inc.
