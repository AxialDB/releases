# AxialDB — evaluation releases

**Proprietary software. Not open source.**

This repository distributes **prebuilt evaluation binaries** for **AxialDB**, a product of **IT ART Inc.** (Canadian corporation). AxialDB is the columnar analytics extension for SQL databases. This repo does **not** contain source code, and it is **not** the full commercial product offering.

## What this repository is for

| Purpose | Description |
|--------|-------------|
| **Evaluation** | Let qualified prospects try AxialDB on their own infrastructure before purchasing a commercial license. |
| **Releases by database** | GitHub [Releases](https://github.com/AxialDB/releases/releases) are organized by target database (for example SQLite, MySQL). Each asset lists version, build date, and evaluation limits. |

## What this repository is not

- **Not** an open-source project (no source, no OSS license).
- **Not** for production use, redistribution, or embedding in shipped products without a commercial agreement.
- **Not** a substitute for a supported commercial build, SLA, or updates.

## License and terms

Downloading, installing, or using any binary from this repository means you accept the **[Evaluation License Agreement](EVALUATION_LICENSE.md)** in full.

GitHub may show **“No license”** on this repository because no open-source license is granted. Your rights come only from `EVALUATION_LICENSE.md` and any separate written agreement with **IT ART Inc.**

## Getting binaries

1. Open **[Releases](https://github.com/AxialDB/releases/releases)**.
2. Choose the release for your database and platform.
3. Read the release notes (evaluation limits, expiry if any, checksums).
4. Install per the instructions in that release.

Evaluation builds may be **time-limited**, **row-limited**, or **feature-limited** compared to commercial builds. See each release’s notes.

## Commercial licenses

Evaluation does not include production rights, redistribution, or priority support.

For commercial licensing, pricing, and supported builds, contact **IT ART Inc.** via the **[AxialDB GitHub organization](https://github.com/AxialDB)** (open an issue or use the contact method published there).

## Product positioning (short)

AxialDB adds **isolated analytical views** inside databases you already run: materialize once to Parquet, run heavy analytics via a sidecar engine, and keep routine OLTP workloads off the hot path for every report.

---

*Evaluation binaries are provided **as is** without warranty. See [EVALUATION_LICENSE.md](EVALUATION_LICENSE.md) for disclaimers and limitation of liability.*
