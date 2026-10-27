# Published releases

Artifact checksums and install docs for each drop. Each zip is attached to its [GitHub Release](https://github.com/AxialDB/releases/releases). The zips are not stored in git.

**6.0.0** is the current free release: 5 tables, 2 of them live, under [TERMS.md](TERMS.md). It has two packages for each system. The **engine** package (engine, `axialdb` command line, ODBC and JDBC drivers) is attached to the `engine/v6.0.0` release; install guides in [engine/](engine/). The optional **MySQL shim** package (the plugin for MySQL 9.7.0, 9.7.1, and 9.7.2, and its bridge) is attached to the `mysql/9.7/v6.0.0` release; install guides in [mysql/9.7/](mysql/9.7/). Use the two packages of the same version together.

| AxialDB | Package | Platform | Build-ID | Released | SHA256 (zip) | Release |
|---------|---------|----------|----------|----------|--------------|---------|
| 6.0.0 | Engine | windows-x64 | 20261027-001 | 2026-10-27 | `e2261228…6fde7` | [engine/v6.0.0](https://github.com/AxialDB/releases/releases/tag/engine/v6.0.0) · [notes](release-notes/engine-v6.0.0.md) |
| 6.0.0 | Engine | linux-x64 | 20261027-001 | 2026-10-27 | `f9daf76b…fb3b7` | [engine/v6.0.0](https://github.com/AxialDB/releases/releases/tag/engine/v6.0.0) · [notes](release-notes/engine-v6.0.0.md) |
| 6.0.0 | MySQL 9.7 shim | windows-x64 | 20261026-002 | 2026-10-27 | `26850543…e146d` | [mysql/9.7/v6.0.0](https://github.com/AxialDB/releases/releases/tag/mysql/9.7/v6.0.0) · [notes](release-notes/mysql-9.7-v6.0.0.md) |
| 6.0.0 | MySQL 9.7 shim | linux-x64 | 20261026-002 | 2026-10-27 | `46671c7f…7e49e` | [mysql/9.7/v6.0.0](https://github.com/AxialDB/releases/releases/tag/mysql/9.7/v6.0.0) · [notes](release-notes/mysql-9.7-v6.0.0.md) |
| 5.0.0 | MySQL 9.7 | windows-x64 | 20260927-006 | 2026-09-27 | `5c65f7ea…95f0` | [v5.0.0](https://github.com/AxialDB/releases/releases/tag/mysql/9.7/windows/v5.0.0) · [notes](release-notes/mysql-9.7-windows-v5.0.0.md) |
| 5.0.0 | MySQL 9.7 | linux-x64 | 20260927-004 | 2026-09-27 | `294b01d4…8aaf` | [v5.0.0](https://github.com/AxialDB/releases/releases/tag/mysql/9.7/linux/v5.0.0) · [notes](release-notes/mysql-9.7-linux-v5.0.0.md) |

Full checksums: [manifests/](manifests/).

Install 6.0.0: engine [Windows](engine/windows/README.md) · [Linux](engine/linux/README.md); MySQL shim [Windows](mysql/9.7/windows/README.md) · [Linux](mysql/9.7/linux/README.md)

5.0.0 is one zip with the engine and the plugin, and does not work with 6.0.0's packages. Its guides and its plugins for MySQL 9.7.0, 9.7.1, and 9.7.2 are in this repository's history: [mysql/9.7 as of 5.0.0](https://github.com/AxialDB/releases/tree/bf11571bd7c7fdcbcc72247d51c5f8824916fc06/mysql/9.7).
