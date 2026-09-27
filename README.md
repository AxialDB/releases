# AxialDB downloads

Prebuilt AxialDB for the databases we support. MySQL is the first. This repository has no source code. The analytical engine is private. The binlog reader it uses, [ce-stream](https://github.com/AxialDB/ce-stream), is a separate open-source project.

## Free version

The current download is free to run within a cap: **5 views**, and **2 of those may be live** (kept up from the database change log). It does not expire. It is the same engine a paid license unlocks. The license file raises the cap and is how a support agreement is made. It does not add a second product.

Read the [terms of use](TERMS.md) before you install. The free version is provided as-is. There is no warranty and no support agreement. You are responsible for backups and for where you run it. We test each release, including CDC under load, and AxialDB does not write to your InnoDB tables. That is not a promise that nothing on your server can go wrong.

The free release is **5.0.0**. Install that tag. Older tags (0.1.0 and 0.1.1) were published under a separate evaluation agreement and stay on that agreement. New downloads use [TERMS.md](TERMS.md).

## Install

| Database | Platform | Guide |
|----------|----------|-------|
| MySQL 9.7 | Windows x64 | [mysql/9.7/windows/README.md](mysql/9.7/windows/README.md) |
| MySQL 9.7 | Linux x64 | [mysql/9.7/linux/README.md](mysql/9.7/linux/README.md) |

Binaries are attached to [GitHub Releases](https://github.com/AxialDB/releases/releases). The guide in the zip is the same text as the links above. Each zip also contains `TERMS.md` and `cdc-limitations.md`.

Published builds: [RELEASES.md](RELEASES.md).

## Paid use

More than 5 views, more than 2 live views, ODBC for Tableau or Power BI, or a support agreement: info@axialdb.com. You receive `axialdb.lic`, place it beside `axialdb.toml`, and restart the AxialDB service.

Copyright (c) 2026 IT ART Inc.
