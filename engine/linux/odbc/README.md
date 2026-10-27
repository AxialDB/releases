# AxialDB ODBC driver

A read-only ODBC driver for `axialdb-engine`. Tableau, Power BI, and any other ODBC program use it to list AxialDB tables and run `SELECT`.

64-bit only. The driver is registered under the name **AxialDB**.

## Install

**Windows.** Put this folder where it will stay, then from an elevated PowerShell:

```powershell
.\register-axialdb-odbc.ps1
```

Windows records the path of `axialdb_odbc.dll`. Run the script again if you move the file. `.\register-axialdb-odbc.ps1 -Remove` takes the registration away.

If PowerShell answers that the script is not digitally signed, the zip was unpacked with the mark Windows puts on a browser download: `Unblock-File .\*.ps1` and run it again, or `powershell -ExecutionPolicy Bypass -File .\register-axialdb-odbc.ps1`. The same applies to `install-tableau-tdc.ps1` below.

**Linux.** Needs unixODBC (Debian and Ubuntu: `apt install unixodbc odbcinst`).

```bash
sudo bash register-axialdb-odbc.sh
```

The driver is copied to `/usr/local/lib/axialdb/` and registered for every user. `sudo bash register-axialdb-odbc.sh --remove` takes it away.

## Connect

```text
Driver={AxialDB};Server=127.0.0.1;Port=9742;DbIdentity=sales;
```

| Keyword | Meaning |
|---------|---------|
| `Server` | The engine's host. Default `127.0.0.1`. |
| `Port` | The engine's port. Default `9742`. |
| `DbIdentity` | Optional. The AxialDB schema this connection works in. `Schema` and `Database` mean the same. |
| `PWD` | The engine's client secret (`client_secret` under `[access]` in the engine's config). An engine asks callers from other machines for it. The user name is ignored. |
| `TlsCa` | Path of a PEM file with the engine's certificate. Setting it encrypts the connection. |
| `AllowRemote` | `1` to connect to an engine on another machine. Without it the driver only connects to this machine. |
| `ConnectTimeout` | Seconds to wait for the engine. Default `10`. |

BI tools show AxialDB schemas as databases. Without `DbIdentity` a connection lists the tables of every schema, and a query names a table as `schema.table`. With `DbIdentity` the connection works in that schema: its tables are listed, and a query names them without a prefix. Either way a query can name a table of any schema as `schema.table`, so one connection, and one query, can join tables from two schemas:

```sql
SELECT c.state, COUNT(*) AS order_lines
FROM demo_perf.order_lines_av o
JOIN mongo.customers c ON c.customer_id = o.customer_id
GROUP BY c.state
```

On Linux, try a connection with `isql -k "Driver={AxialDB};Server=127.0.0.1;Port=9742;DbIdentity=sales;"`.

## Tableau Desktop

Tableau needs the customization file `axialdb_odbc.tdc`, which tells it how this driver behaves. Without it Tableau does not work well with the driver.

1. Run `.\install-tableau-tdc.ps1` (no administrator rights needed), or copy `axialdb_odbc.tdc` into `Documents\My Tableau Repository\Datasources` yourself.
2. Close Tableau completely and start it again.
3. Connect, More, Other Databases (ODBC), Driver: AxialDB. To work in one schema, put `DbIdentity=<schema>;` into **String Extras**. Leave it out to reach every schema from this connection: a join of tables from two schemas then runs in the engine, where two connections make Tableau fetch both tables and join them itself.

Tableau's `log.txt` (in `My Tableau Repository\Logs`) has a line "Found matching TDC" that names the file when it is in use.

Use a **Live** connection for large tables, so that the grouping runs in the engine.

## Power BI Desktop

Get Data, ODBC, with the connection string above (or a DSN). Power BI imports what it reads, so for a large or wide table give it a query that returns only the columns and rows the report needs (Advanced options, SQL statement).

## Trace

For a support question, the driver can write what a program asks of it to a file: set the environment variable `AXIALDB_ODBC_TRACE=1` (the file is `%TEMP%\axialdb_odbc_trace.log`, or the path in `AXIALDB_ODBC_TRACE_FILE`) for the program, then start it. Unset it afterwards; nothing the driver ships sets it.

## What the driver does not do

- It does not write. `INSERT`, `UPDATE`, `DELETE`, and DDL are refused. Tables are created with the `axialdb` command line or in MySQL.
- 32-bit programs cannot load it.
