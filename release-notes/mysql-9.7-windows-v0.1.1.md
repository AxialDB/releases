## AxialDB 0.1.1 - MySQL 9.7 Windows x64 (eval)

**Artifact:** `axialdb-mysql-9.7-windows-x64-0.1.1.zip`  
**Build-ID:** `20260615-002`  
**SHA256:** `a411517282411ae47054b8763e672bf73cbf1af8621e3a2cd232c78f6656b7be`  
**Released:** 2026-06-16  
**GitHub Release:** [mysql/9.7/windows/v0.1.1](https://github.com/AxialDB/releases/releases/tag/mysql/9.7/windows/v0.1.1)

Pre-release evaluation only. Not for production. See [EVALUATION_LICENSE.md](../EVALUATION_LICENSE.md).

### Install

Full steps are in the zip (`README.md`) and in the repo:  
[mysql/9.7/windows/README.md](https://github.com/AxialDB/releases/blob/main/mysql/9.7/windows/README.md)

**Important:** `axialdb.toml` is an example with default paths. Copy it to a permanent location, edit for your environment, and set `AXIALDB_CONFIG` to that file. Start the **AxialDBEngine** Windows service before `axialdb_init()` or CTAS.

### Changes in 0.1.1

- **CTAS defaults to snapshot** — no silent `pre_aggregate` when CREATE options are omitted (fixes row-count mismatch and materialize errors on narrow tables).
- **Column pruning** — `SELECT * … WHERE …` no longer drops non-predicate columns (fixes NULL/zero columns on filtered scans).
- **Typed CTAS batches** — bridge infers Int64/Float64/Utf8 from cell text.
- **Catalog rename** — `RENAME TABLE` syncs analytics catalog via IPC.
- **Janitor orphan sweep** — optional `mysql_datadir` for read-only `.sdi` checks on published views.
- **Engine singleton lock** — one `axialdb-engine` per data directory.
- **IPC `TCP_NODELAY`** — bridge + sidecar disable Nagle on loopback TCP (repeat analytics performance on all platforms).

### Upgrade from 0.1.0

Stop **MySQL97** and **AxialDBEngine**, replace plugin DLLs + `axialdb-engine.exe`, restart sidecar then MySQL. Re-run `install-axialdb-mysql-functions.sql` only if UDF registration changed (same SONAME).
