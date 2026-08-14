---
paths:
  - "**/*.sql"
  - "**/*migration*"
  - "**/*migrate*"
---

# SQL Rules

> DDL, DML, performance, security.

## General

- **Explicit columns** — no `SELECT *` (except aggregates)
- Keywords uppercase: `SELECT`/`FROM`/`WHERE`/`JOIN`/`ON`
- Identifiers lowercase + underscore: `user_profile.created_at`
- Strings single-quoted `'value'`
- No `OR` chains of 5+ — use `IN` or a temp table
- No "lucky" statements in prod beyond `LIMIT 1`

## Performance

### WHERE must hit an index

New queries annotate the expected index:
```sql
-- expected: idx_user_status_created (status, created_at DESC)
SELECT id, name FROM users
WHERE status = 'active' AND created_at > '2026-01-01'
ORDER BY created_at DESC
LIMIT 20;
```

### JOINs

- Max **3 tables** per query
- Over 3 → rewrite (split / materialized view / temp table) or question if the join is needed
- Explicit `INNER`/`LEFT` — no bare `JOIN`

### Pagination — keyset, not OFFSET

❌ `OFFSET` kills deep pagination:
```sql
SELECT * FROM orders ORDER BY id LIMIT 20 OFFSET 10000;  -- slow
```

✅ keyset:
```sql
SELECT * FROM orders WHERE id > $last_id ORDER BY id LIMIT 20;
```

### Subquery vs JOIN

- Scalar subquery (single value) — OK
- Large dataset → JOIN
- `IN (subquery)` slow on big tables → `EXISTS` or JOIN

## DDL

### Must be reversible

Each up pairs with a down:
```
migrations/
├── 20260610_add_user_status.up.sql
└── 20260610_add_user_status.down.sql
```

### Large tables

- Add column: NULL or explicit default — no NOT NULL without default (locks)
- Add index: `CREATE INDEX CONCURRENTLY` (Postgres) / online DDL (MySQL 8)
- Drop column: two steps — deprecate, observe, then drop
- No large `ALTER` during working hours

### Naming

- Tables: `snake_case`, singular (`user` per team convention)
- Primary key: `id` (bigint/uuid)
- Relation field: `<ref_table>_id` (`user_id`), with the same type as the referenced primary key
- Index: `idx_<table>_<cols>`
- Unique: `uniq_<table>_<cols>`
- Timestamps: `created_at`/`updated_at`/`deleted_at` (soft delete)

### Names and comments

- Avoid generic or reserved/conflicting names (for example `status`, `type`, `order`, `group`, `user`, `key`); qualify business fields, for example `order_status`.
- New tables and columns require a database `COMMENT` with their business meaning.

### Relationships: primary keys only

- Use primary keys only; do not define database foreign keys (`FOREIGN KEY`, `REFERENCES`, or foreign-key `CONSTRAINT`).
- Model relationships with `<ref_table>_id`, validate them in application logic, and index the field when needed.

## DML

### Writes need a transaction

```sql
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;
```

Idempotent cases (unique-key INSERT with ON CONFLICT) may skip.

### UPDATE/DELETE need WHERE

- No WHERE → refuse outright
- `SELECT` the same condition first to check affected rows
- Large changes (>10k rows) → batch, not all at once

### INSERT — batch

```sql
-- no loop single-row inserts
INSERT INTO logs (level, msg) VALUES
('info', 'a'),
('info', 'b'),
('info', 'c');
```

## Security

- No string-concatenated SQL (injection)
- Parameterized queries / prepared statements
- Don't log raw SQL (may leak sensitive data)
- DROP/TRUNCATE/DELETE without WHERE = dangerous (see AGENTS.md security red line)

## Pre-Write Checklist

- [ ] WHERE hits an index?
- [ ] JOIN ≤ 3 tables?
- [ ] Keyset pagination, not OFFSET?
- [ ] Writes in a transaction?
- [ ] UPDATE/DELETE have WHERE?
- [ ] DDL has a down migration?
- [ ] Relationships use `<ref_table>_id`; no database foreign key?
- [ ] Tables and new columns have `COMMENT`s; business fields are qualified?
- [ ] No string concat (parameterized)?

## Forbidden

- `SELECT *` (except aggregates)
- Bare `JOIN` (must be INNER/LEFT)
- `OFFSET` for deep pagination
- Prod `DROP TABLE`/`TRUNCATE` without notice
- UPDATE/DELETE without WHERE
- Database foreign keys (`FOREIGN KEY`, `REFERENCES`, foreign-key `CONSTRAINT`)
- Generic/reserved names or missing `COMMENT`s on new tables and columns
- `SELECT ... FOR UPDATE` on hot path without timeout
- Implicit type conversion (`WHERE id = '123'`)
