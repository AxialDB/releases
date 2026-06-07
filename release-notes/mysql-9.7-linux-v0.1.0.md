## AxialDB 0.1.0 - MySQL 9.7 Linux x64 (eval)

**Artifact:** `axialdb-mysql-9.7-linux-x64-0.1.0.zip`  
**Build-ID:** `20260607-001`  
**SHA256:** `9baf99ffe79377bd43244afb9c63dc49bc11ce545c358a0cc2ad88e7333dfb64`  
**Released:** 2026-06-07

Pre-release evaluation only. Not for production. See [EVALUATION_LICENSE.md](../EVALUATION_LICENSE.md).

### Install

Full steps are in the zip (`README.md`) and in the repo:  
[mysql/9.7/linux/README.md](https://github.com/AxialDB/releases/blob/main/mysql/9.7/linux/README.md)

**Important:** `axialdb.toml` is an example with default paths. Copy it to a permanent location, edit for your environment, set `AXIALDB_CONFIG` for **mysqld** (systemd) and start `axialdb-engine` with the same config.

### Changes in 0.1.0

- First public MySQL 9.7 Linux x64 eval release (sidecar-only; same scope as Windows v0.1.0).
