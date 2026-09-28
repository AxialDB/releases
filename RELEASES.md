# Published releases

Artifact checksums and install docs for each drop. Each zip is attached to its [GitHub Release](https://github.com/AxialDB/releases/releases). The zips are not stored in git.

**5.0.0** is the free release: 5 views, 2 of them live, under [TERMS.md](TERMS.md). Each zip has the engine, the bridge, and the plugin for MySQL 9.7.0. The plugin and the bridge are also in this repository: [mysql/9.7/windows](mysql/9.7/windows) and [mysql/9.7/linux](mysql/9.7/linux). The plugin file is `ha_axialdb-<version>-windows-x64.dll` or `ha_axialdb-<version>-linux-x64.so`. Later 9.7 patches are added there as new files. Fixes are built only for the newest patch. Older plugin files stay and are not rebuilt.

| AxialDB | Product | Platform | Build-ID | Released | SHA256 (zip) | Release |
|---------|---------|----------|----------|----------|--------------|---------|
| 5.0.0 | MySQL 9.7 | windows-x64 | 20260927-006 | 2026-09-27 | `5c65f7ea…95f0` | [v5.0.0](https://github.com/AxialDB/releases/releases/tag/mysql/9.7/windows/v5.0.0) · [notes](release-notes/mysql-9.7-windows-v5.0.0.md) |
| 5.0.0 | MySQL 9.7 | linux-x64 | 20260927-004 | 2026-09-27 | `294b01d4…8aaf` | [v5.0.0](https://github.com/AxialDB/releases/releases/tag/mysql/9.7/linux/v5.0.0) · [notes](release-notes/mysql-9.7-linux-v5.0.0.md) |

Install: [mysql/9.7/windows/README.md](mysql/9.7/windows/README.md) · [mysql/9.7/linux/README.md](mysql/9.7/linux/README.md)
