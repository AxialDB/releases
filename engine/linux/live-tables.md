# Live tables: what they can be

A **snapshot** table is a copy of a query's result, made once. Any query its source can run is fine, and the table is refreshed by creating it again.

A **live** table follows its source: inserts, updates, and deletes reach it on their own, usually within a few seconds. AxialDB reads the MySQL binlog or the MongoDB change stream itself; you run nothing else. In exchange, the query that defines a live table is restricted to what AxialDB can keep correct change by change. A live create outside the rules below **fails**, with a message that names the rule. It never falls back to a snapshot without saying so.

AxialDB tables are **read-only**. Changes come from the source tables and collections.

The free version allows **5 tables**, **2 of them live**, from all sources together. A sixth table, or a third live table, is refused; existing tables stay. A license file beside the engine's `axialdb.toml` lifts the caps after a restart of the engine. Contact info@axialdb.com. Use is as-is; see `TERMS.md`.

## Status

A new live table answers no query until it has caught up with its source. Then its status is `healthy`:

```bash
axialdb query "SELECT schema_name, table_name, status FROM axialdb.tables"
```

From inside MySQL: `SELECT axialdb_cdc_status('your_db', 'your_table');`

| Status | Meaning |
|--------|---------|
| `healthy` | Following its source. |
| `catching_up` | Reading the changes made since its first copy. Queries are refused until it is `healthy`. |
| `updating N% of a change of R rows` | A large change to its source (10,000 rows or more) is being applied, or waits for its turn. Queries still answer, from the table as it was before the change; the change shows all at once when it is applied. For a star whose change goes through the copies of its tables first, the copies take the first half of the percentage. |
| `updating (receiving a change: R rows so far)` | A large transaction on its source is still arriving. Queries answer as above. |
| `stale since <time>` | Its source cannot be reached. The table still answers, from the last data it received, and returns to `healthy` by itself. |
| `failed: <reason>` | It stopped following its source, and the reason says why. Drop it and create it again. |

---

## MySQL

A live MySQL table is made by `CREATE TABLE ... ENGINE=AXIALDB COMMENT='live' AS SELECT ...` in a MySQL server with the AxialDB plugin, or by `axialdb create-table <db>.<table> --source <name> --mode live --query "SELECT ..."` on any MySQL server. The engine checks the query the same way, whichever way it arrives.

**What the server needs:** `binlog_format=ROW`, `binlog_row_image=FULL`, `binlog_row_metadata=FULL`, `gtid_mode=ON`. **What the engine needs**, under the source's `[sources.<name>]` in its `axialdb.toml`: `user`, its own account, which reads the source tables' columns and keys (`SELECT`, and `SHOW VIEW` for views); and `capture_user`, which reads the binlog (`REPLICATION SLAVE`, `REPLICATION CLIENT`, `SELECT`). Neither account stands in for the other. The install guide has the statements.

### The query

| Allowed | Refused |
|---------|---------|
| One table, or a **star**: a fact table joined to dimension tables, `F LEFT JOIN D*` or `F JOIN D*` | A self-join, a join inside parentheses on the right side of another join, `UNION`, no `FROM` |
| Joins on `F.fk = D.pk` only, the dimension's **PRIMARY KEY**. An inner join keeps the fact rows that have their dimension row | A join on a UNIQUE index or another column, a non-equal join, a further condition in the `ON` of a `LEFT JOIN` (put the filter in the `WHERE`) |
| Source columns, renamed or not, except the fact table's key columns | Expressions, functions, casts, `CASE` |
| `WHERE` with `AND`, `OR`, `NOT`, a column against a literal (`= <> < <= > >=`), `IS [NOT] NULL`, `[NOT] IN (literals)` | A comparison of two columns, `GROUP BY`, `HAVING`, `DISTINCT`, windows, `LIKE`, `REGEXP`, subqueries in `WHERE`, functions |
| A view, a subquery in `FROM`, or a `WITH` name that is itself a plain select of columns, with or without a `WHERE`. It is read through to its tables, as MySQL does | One with `GROUP BY`, `DISTINCT`, `LIMIT`, or `UNION`; `WITH RECURSIVE`; one with a `WHERE` as the right side of a `LEFT JOIN`; one that reads several tables, joined as a dimension |
| `ORDER BY` columns of the select list, with `LIMIT` (below) | `ORDER BY` an expression, or a column that is not in the select list; `FETCH` |
| At most **100** columns | More |

**Totals and groups belong in the queries you run on the live table**, not in its definition. Make the grain live (a fact table and its dimensions) and `GROUP BY` when you query it, or make the aggregate a snapshot.

**`ORDER BY` with `LIMIT`** keeps the table to the current top N: `SELECT id, total FROM orders ORDER BY total DESC LIMIT 10` always shows the ten largest orders, as the query would. The table stores every row its `WHERE` lets through and applies the order and the limit when it is read, so a query's own `WHERE` on it applies to those N rows. The ordering columns are columns of the select list (by name, or by position as in `ORDER BY 2`), of the types allowed in `WHERE`. `LIMIT offset, count` and `LIMIT count OFFSET offset` both work. NULLs come first in ascending order and last in descending order, as in MySQL. The engine makes the first copy of such a table itself, with the source's `user` account.

### Keys

- Every source table needs a **PRIMARY KEY**. Every key column of the fact table (the one table, or the first table of a star) is in the `SELECT` under its own name, written exactly as the table declares it: `id AS order_id` is refused, and so is `SELECT ID` for a column `id` (write `id`, or `ID AS id`). Every other column may be renamed.
- The fact column a join is made on is in the `SELECT`, under any name. A dimension's key column may be left out or renamed.
- An `UPDATE` that changes a primary key on a source table is followed: the row is in the table under its new key only.

### Types

- Allowed in joins and in `WHERE`: whole numbers, `BOOLEAN`, `DATE`, `DATETIME`, `TIMESTAMP`, `DECIMAL`, and `VARCHAR` or `TEXT` with collation **`utf8mb4_0900_bin`**. `FLOAT` and `DOUBLE` in `WHERE`.
- A number in `WHERE` has no exponent (`0.5`, not `5e-1`). A `TIMESTAMP` column is compared with a date, or a date and time (`'2026-01-31 14:00:00'`), read in the session's time zone as MySQL reads it.
- `CHAR` and `TIME` may be selected and not used in `WHERE`. A `TIME` column is text in AxialDB.
- Refused in a live table: `JSON`, `ENUM`, `SET` (they work in a snapshot), binary columns, `BIT`, spatial types, and collations that pad with spaces (`utf8mb4_bin` among them) on a join or filter column.
- A MyISAM source table is accepted. Its first copy holds a read lock on the table and is not one snapshot with the other tables; the changes that follow make up for that.

### Changes on the source

| On the source table | The live table |
|---------------------|----------------|
| `INSERT`, `UPDATE`, `DELETE` | Applied |
| `REPLACE`, `LOAD DATA`, `ON DUPLICATE KEY UPDATE` | Applied as the inserts, updates, and deletes MySQL logs for them |
| `TRUNCATE`, `DROP TABLE`, `RENAME TABLE`, `DROP DATABASE` | Stops: `failed`, naming the statement. Drop it and create it again |
| `ALTER TABLE` that drops or changes a column the table uses, or changes the primary key | Stops the same way |
| `ALTER TABLE` that adds a column, changes an index, or touches a column the table does not use | No effect |

---

## MongoDB

A live Mongo table is made with `axialdb create-table <schema>.<table> --source <name> --mode live --query "SELECT ..."`. The query is a small SQL dialect that AxialDB reads; the collection is named in `FROM` with its database.

**What the server needs:** MongoDB **8.0 or newer**, as a **replica set** (one member is enough; a standalone server has no change stream). Sharded clusters are not supported. On each source collection, once, `changeStreamPreAndPostImages` enabled (`db.runCommand({ collMod: "orders", changeStreamPreAndPostImages: { enabled: true } })`). An oplog window longer than the longest time the engine is down, plus the time of a first copy. **What the engine needs:** an account with the `read` role on the source database, in the source's `uri`.

### The query

```sql
SELECT _id,
       CAST(customer_id AS BIGINT) AS customer_id,
       legal_name,
       address.city AS city,
       contacts[0].first_name AS first_contact
FROM crm.customers
WHERE address.state = 'GA' AND CAST(customer_id AS BIGINT) >= 100
```

- **`_id` is required**, under that name, and is the table's key. It is never cast or renamed; select it a second time for a typed copy (`CAST(_id AS BIGINT) AS id_value`). It is stored as text: an ObjectId as its 24 hex characters, a number as its digits, a document as plain JSON.
- **Field paths:** a dot steps into a nested object, `[n]` reads an array element counted from 0. A missing field is `NULL`. A whole object or array as a column is stored as JSON text. A nested path without `AS` is named with `_` between its steps (`address_city`).
- **Types:** a field without `CAST` is text. `CAST(path AS BIGINT | DOUBLE | DECIMAL(p,s) | BOOLEAN | TIMESTAMP | DATE | VARCHAR)` gives a real column of that type. A value that is present and does not convert is an error, not `NULL`: the create is refused, or a live table becomes `failed` and names the document. Binary and other rare Mongo types are refused.
- **`WHERE`:** `= <> < <= > >=`, `IN`, `IS [NOT] NULL`, `AND`, `OR`, `NOT`, on field paths (cast or not) and literals of the same kind: `n = 5` is refused, `CAST(n AS BIGINT) = 5` and `n = '5'` are accepted. A `TIMESTAMP` literal carries its zone (`'2026-02-01T00:00:00Z'`). A whole array or object is not compared; pick an element or a field.
- **Names** are lowercased (`AS firstName` is `firstname`). Two columns of one name are refused. A name with other characters is written in double quotes: `"first-name" AS first_name`, `FROM "orders-2024"`.
- **Refused:** `SELECT *`, joins, `GROUP BY`, `ORDER BY`, `LIMIT`, functions other than `CAST`. Join or reshape in MongoDB: write the result into a collection with `$merge` on your own schedule, and make the live table from that collection. A collection written by `$out` cannot be followed. A MongoDB view (`createView`) can be a snapshot table only.

### Changes on the source

| On the source collection | The live table |
|--------------------------|----------------|
| Insert, update, replace, delete | Applied: a document that matches the `WHERE` is the row, one that no longer matches leaves the table |
| Drop or rename of the collection, drop of the database | Stops: `failed`. Create the table again |
| The engine is down for longer than the oplog keeps | Stops: the change stream cannot resume. Create the table again |
