# CDC view limitations (MySQL)

This release can keep an AxialDB table fresh from the MySQL ROW binlog. That path is **opt-in and restrictive**. If `COMMENT='cdc'` is present and the `SELECT` is outside this list, **CREATE fails**. There is no silent fallback to a snapshot.

Snapshot create (`ENGINE=AXIALDB` **without** `cdc`) is unchanged: any `SELECT` MySQL can run for the seed is fine. Recreate the table to refresh.

AxialDB tables are **read-only**. You do not `INSERT` / `UPDATE` / `LOAD` into them. Changes come from the **source** InnoDB tables.

---

## How you ask for CDC

```sql
CREATE TABLE report ENGINE=AXIALDB COMMENT='cdc'
AS
SELECT ...
FROM fact F
LEFT JOIN dim1 D1 ON F.d1_id = D1.id
WHERE ...;
```

`SELECT` on the new table fails until the view is **healthy** (not while it is catching up). Poll:

```sql
SELECT axialdb_cdc_status('your_db', 'report');
```

---

## Defining query (the CREATE `SELECT`)

This is the SQL AxialDB must maintain, not the SQL you run later on the view.

| Allowed | Rejected (CREATE fails) |
|---------|-------------------------|
| One InnoDB table, or a **star**: `F LEFT JOIN D*` | Self-join, nested join, `UNION`, derived tables, no `FROM` |
| Join only `F.fk = D.pk` (dim **PRIMARY KEY**, not a UNIQUE index) | Join on a non-PK unique, non-equi join, user `INNER JOIN` without a dim `WHERE` |
| Source columns only; aliases on **non-PK** columns | Expressions, functions, casts, `CASE`, computed columns |
| `WHERE` / `ON`: `AND` / `OR` / `NOT`, column vs literal `= <> < <= > >=`, `IS [NOT] NULL`, `IN (literals)` | `GROUP BY`, `HAVING`, `DISTINCT`, windows, `LIKE` / `REGEXP`, subqueries, UDFs |
| Width at most **100** columns | Wider projection |

**`GROUP BY` on CREATE is not CDC.** Aggregate that query as a **snapshot**, or CDC the grain (fact + dims) and `GROUP BY` when you `SELECT` from the view.

---

## Keys and indexes

- Every CDC source table needs a **PRIMARY KEY**. Every key part must appear in the `SELECT` (same names as the source for PK columns).
- Join keys on the dimension side are that **PRIMARY KEY** only. A secondary or UNIQUE index is not enough.
- You do **not** `CREATE INDEX` on the AxialDB table. It is not InnoDB. Repeat queries use the sidecar and columnar files.
- A source `UPDATE` that **changes the primary key** is a known hole: the new key is upserted; the old key is not deleted. Avoid PK updates on CDC sources, or recreate the view.

---

## Types and collation

Allowed in join keys, `WHERE`, and `ON`: integer family, `BOOLEAN`, `DATE` / `DATETIME` / `TIMESTAMP`, `DECIMAL`, `VARCHAR` / `VARBINARY` with collation **`utf8mb4_0900_bin`**.

`FLOAT` / `DOUBLE` / `CHAR` may be **projected** but must not be join or equality/`IN` keys.

Rejected for CDC: `JSON`, `ENUM`, `SET`, `BIT`, spatial types; PAD SPACE collations (including `utf8mb4_bin`) on join or filter columns.

---

## After the view is healthy (source DML)

| On the InnoDB source | CDC view |
|----------------------|----------|
| `INSERT` / `UPDATE` / `DELETE` (ROW binlog) | Applied |
| `REPLACE` / `LOAD` / `ON DUPLICATE` | Only if MySQL logs them as insert / update / delete |
| `TRUNCATE` | Resync required |
| Binlog format other than ROW | Not supported |

Source changes typically appear in a **few seconds**. Time varies with load and how much is changing.

---

## Free tier

This zip allows **5 views** total, and only **2** of them may be CDC. A sixth view or a third CDC view fails CREATE. Paid customers get a license file for the **same** engine binary (copy next to `axialdb.toml` and restart). Contact `info@axialdb.com`.

Use is as-is; see `TERMS.md`.
