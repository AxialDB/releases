# AxialDB evaluation releases

**Proprietary software. Not open source.**

This repository distributes **prebuilt evaluation binaries** for **AxialDB**, a product of **IT ART Inc.** (Ontario, Canada). AxialDB is the columnar analytics extension for SQL databases. This repository does **not** contain source code, does **not** grant any open-source license, and is **not** the full commercial product offering.

## What this repository is for

| Purpose | Description |
|--------|-------------|
| **Evaluation** | Let qualified prospects test AxialDB in non-production environments before purchasing a commercial license. |
| **Releases by database** | GitHub [Releases](https://github.com/AxialDB/releases/releases) are organized by target database (for example SQLite, MySQL). Each asset lists version, build date, and evaluation limits. |

## What this repository is not

- **Not** an open-source project (no source, no OSS license).
- **Not** for production use, redistribution, or embedding in shipped products without a commercial agreement.
- **Not** a substitute for a supported commercial build, SLA, or updates.
- **Not** intended for production databases, business-critical workloads, regulated data, or any data that has not been backed up.
- **Not** a contribution repository. Issues, pull requests, forks, and reuse of the binaries are not part of the evaluation license.

## License and terms

Downloading, installing, or using any binary from this repository means you accept the **[Evaluation License Agreement](EVALUATION_LICENSE.md)** in full.

GitHub may show **“No license”** on this repository because no open-source license is granted. Your rights come only from `EVALUATION_LICENSE.md` and any separate written agreement with **IT ART Inc.**

Evaluation binaries are provided **AS IS**, without warranty, support commitment, production rights, or responsibility for data loss, database corruption, downtime, or other damages. Review the Evaluation License Agreement before downloading or running any release.

## Getting binaries

1. Open **[Releases](https://github.com/AxialDB/releases/releases)**.
2. Choose the release for your database and platform.
3. Read the release notes (evaluation limits, expiry if any, checksums).
4. Install per the instructions in that release (also in the zip `README.md`).

### Install guides (in repo)

| Database | Platform | Guide |
|----------|----------|-------|
| MySQL 9.7 | Windows x64 | [`mysql/9.7/windows/README.md`](mysql/9.7/windows/README.md) |
| MySQL 9.7 | Linux x64 | [`mysql/9.7/linux/README.md`](mysql/9.7/linux/README.md) (planned) |

Published versions: [`RELEASES.md`](RELEASES.md).

Evaluation builds may be **time-limited**, **row-limited**, or **feature-limited** compared to commercial builds. See each release’s notes.

Before testing, use disposable or backed-up databases only. Do not connect evaluation builds to production systems unless you have a separate written commercial agreement with IT ART Inc.

## Commercial licenses

Evaluation does not include production rights, redistribution, or priority support.

For commercial licensing, pricing, and supported builds, contact **IT ART Inc.** via the **[AxialDB GitHub organization](https://github.com/AxialDB)** (open an issue or use the contact method published there).

## Product positioning (short)

AxialDB adds **isolated analytical views** inside databases you already run: materialize once to Parquet, run heavy analytics via a sidecar engine, and keep routine OLTP workloads off the hot path for every report.

---

Copyright (c) 2026 IT ART Inc. All rights reserved.

*Evaluation binaries are provided **AS IS** without warranty. See [EVALUATION_LICENSE.md](EVALUATION_LICENSE.md) for disclaimers, exclusions of damages, and limitation of liability.*
