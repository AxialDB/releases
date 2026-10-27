# AxialDB JDBC driver

A read-only JDBC driver for `axialdb-engine`. DBeaver and other Java programs use it to list AxialDB schemas and tables and run `SELECT`.

Two files, kept in the same folder:

- `axialdb-jdbc.jar`
- the native library: `axialdb_jdbc.dll` on Windows, `libaxialdb_jdbc.so` on Linux

Needs Java 17 or later, 64-bit.

## Connect

```text
jdbc:axialdb://127.0.0.1:9742
jdbc:axialdb://127.0.0.1:9742/sales
```

- **Driver class:** `com.axialdb.jdbc.AxialDbDriver`
- **The path after the port** is the default schema for names without a prefix. `schema.table` works with or without it, so one query can join tables of several schemas.
- **User:** ignored.
- **Password:** the engine's client secret (`client_secret` under `[access]` in the engine's config). An engine asks callers from other machines for it. Leave it empty for an engine that has none.
- **Property `tlsCa`:** path of a PEM file with the engine's certificate. Setting it encrypts the connection.

The driver loads the native library from the folder that holds the jar. If it cannot, name the file with the Java option `-Daxialdb.native=<full path of the library>`.

## DBeaver

1. Database, Driver Manager, New.
2. Class name: `com.axialdb.jdbc.AxialDbDriver`
3. URL template: `jdbc:axialdb://{host}:{port}`
4. Libraries: add `axialdb-jdbc.jar`.
5. New connection: the engine's host, port `9742`, any user name, and the client secret as the password when the engine has one.

## Column types

A date, timestamp, or decimal column is `DATE`, `TIMESTAMP`, or `DECIMAL` in the result set metadata. `getDate`, `getTimestamp`, `getBigDecimal`, and `getObject` return `java.sql.Date`, `java.sql.Timestamp`, and `java.math.BigDecimal`.

## What the driver does not do

It does not write. Tables are created with the `axialdb` command line or in MySQL.
