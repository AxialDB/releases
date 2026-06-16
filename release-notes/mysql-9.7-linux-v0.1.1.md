## AxialDB 0.1.1 - MySQL 9.7 Linux x64 (eval)

**Artifact:** `axialdb-mysql-9.7-linux-x64-0.1.1.zip`  
**Build-ID:** `20260615-002`  
**SHA256:** `d7867eb5e8a2c671c091c0932bc082bc806c6e53c1d3ba69c68999a8902f084d`  
**Released:** 2026-06-16  
**GitHub Release:** [mysql/9.7/linux/v0.1.1](https://github.com/AxialDB/releases/releases/tag/mysql/9.7/linux/v0.1.1)

Pre-release evaluation only. Not for production. See [EVALUATION_LICENSE.md](../EVALUATION_LICENSE.md).

### Install

Full steps are in the zip (`README.md`) and in the repo:  
[mysql/9.7/linux/README.md](https://github.com/AxialDB/releases/blob/main/mysql/9.7/linux/README.md)

**Important:** Copy `axialdb.toml` to `/etc/axialdb/axialdb.toml`, set `AXIALDB_CONFIG` for **mysqld** and the sidecar unit, and run `sudo chown -R mysql:mysql /var/lib/axialdb /var/log/axialdb` before starting **axialdb-engine.service**.

### Changes in 0.1.1

Same kernel and plugin fixes as Windows v0.1.1 (see [windows release notes](mysql-9.7-windows-v0.1.1.md)).

Linux-specific:

- Zip includes **`axialdb-engine.service`** (systemd sidecar unit).
- **`TCP_NODELAY` on loopback IPC** — fixes CTAS/GROUP BY stalls on Linux/WSL2 when upgrading from 0.1.0.
- Install README: `chown mysql:mysql` on data/log dirs, troubleshooting for slow IPC on older builds.

### Upgrade from 0.1.0

Stop **mysql** and **axialdb-engine**, replace both `.so` files + `axialdb-engine` binary, install/update the systemd unit if missing, restart sidecar then MySQL.
