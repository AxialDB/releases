# Published releases

Artifact checksums and install docs for each drop. Binaries are attached to [GitHub Releases](https://github.com/AxialDB/releases/releases), not stored in git.

**5.0.0** is the free release: 5 views, 2 of them live, under [TERMS.md](TERMS.md). The engine zip is attached to the GitHub release, not stored in git. The plugin and the bridge are in this repository: [mysql/9.7/windows](mysql/9.7/windows) and [mysql/9.7/linux](mysql/9.7/linux). The plugin file is `ha_axialdb-<version>-windows-x64.dll` or `ha_axialdb-<version>-linux-x64.so`. The first version is `9.7.0`. Later 9.7 patches are added as new files. Fixes are built only for the newest patch. Older plugin files stay and are not rebuilt.

| AxialDB | Product | Platform | Build-ID | Released | SHA256 (zip) | Release |
|---------|---------|----------|----------|----------|--------------|---------|
| 5.0.0 | MySQL 9.7 | windows-x64 | 20260927-001 | 2026-09-27 | `bed57a97…8434` | [v5.0.0](https://github.com/AxialDB/releases/releases/tag/mysql/9.7/windows/v5.0.0) · [notes](release-notes/mysql-9.7-windows-v5.0.0.md) |
| 5.0.0 | MySQL 9.7 | linux-x64 | 20260927-001 | 2026-09-27 | `fb872f81…45cc` | [v5.0.0](https://github.com/AxialDB/releases/releases/tag/mysql/9.7/linux/v5.0.0) · [notes](release-notes/mysql-9.7-linux-v5.0.0.md) |

Install: [mysql/9.7/windows/README.md](mysql/9.7/windows/README.md) · [mysql/9.7/linux/README.md](mysql/9.7/linux/README.md)
