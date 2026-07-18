# SQL Revision — Optimised Reference
### Manish Tiwari course, distilled for Data Engineering. Lookup sheet, not a syllabus.

**How to use this:** Ctrl-F it when you hit something mid-project. Do not read it front to back. If you find yourself "going through" this file, you are avoiding your pipeline.

**Cut from the original notes, deliberately:** `CREATE DATABASE`/`USE`/`DROP DATABASE`, row-by-row `INSERT ... VALUES` drills, `SELECT *` warmups, basic `WHERE`/`ORDER BY`, `FOR XML AUTO`, aggregate function definitions. You know these. Re-practising them is comfort.

**Not cut, despite looking basic:** data types, NULL semantics, `INSERT ... SELECT`, constraints-as-modelling. These look like beginner material and cause production incidents. See §1.

---

## 0. The dialect problem — read once, internalise

Your course is **T-SQL (SQL Server)**. You practise in **MySQL**. These fail or misbehave when copied across:

| Concept | T-SQL (course) | MySQL (your Workbench) |
|---|---|---|
| Top N | `SELECT TOP 3 *` | `... LIMIT 3` |
| Table from query | `SELECT * INTO new FROM old` | `CREATE TABLE new AS SELECT * FROM old` |
| Now | `GETDATE()` | `NOW()` / `CURDATE()` |
| Auto-increment | `IDENTITY(1,1)` | `AUTO_INCREMENT` |
| Change column type | `ALTER COLUMN x VARCHAR(20)` | `MODIFY COLUMN x VARCHAR(20)` |
| Proc parameter | `@dept_id INT` | `IN dept_id INT` |
| Run proc | `EXEC p` | `CALL p()` |
| Batch separator | `GO` (SSMS only — not SQL) | `DELIMITER //` |
| Trigger deleted rows | `FROM DELETED` (set) | `OLD.col` (one row, `FOR EACH ROW`) |
| Trigger types | BEFORE / AFTER / INSTEAD OF | BEFORE / AFTER only |
| Full outer join | `FULL JOIN` | Unsupported — `LEFT ... UNION RIGHT ...` |

Databricks/Snowflake later: both have `QUALIFY`, which collapses the CTE+ROW_NUMBER+filter dance into one line. Neither T-SQL nor MySQL has it.

---

## 1. The basics that actually bite

Not for practice. For not corrupting data.

**Types**
- `DECIMAL(p,s)` for money. Never `FLOAT` — binary floating point can't represent 0.1 exactly, and rounding drift in financial columns is a real incident.
- `VARCHAR(n)` sizing: too small truncates silently in some configs, errors in others. Know which your engine does.
- `DATETIME` has no timezone. Decide UTC-vs-local at ingestion, once, and document it.

**NULL semantics — three-valued logic**
- `NULL = NULL` → unknown, not true. Use `IS NULL`.
- `NOT IN (subquery)` returns **zero rows** if the subquery yields even one NULL. Use `NOT EXISTS` instead. This is the single most common silent-wrong-answer bug in SQL.
- `salary + NULL` → NULL. Guard with `COALESCE(bonus, 0)`.
- `COUNT(col)` skips NULLs; `COUNT(*)` doesn't.
- Aggregates ignore NULLs — `AVG(col)` over 10 rows with 4 NULLs divides by 6, not 10.

```sql
SELECT name, COALESCE(phone, 'Unknown') FROM employees;
SELECT name, COALESCE(email, alternate_email, 'Unknown') FROM employees;  -- fallback chain
SELECT salary + COALESCE(bonus, 0) AS total_pay FROM employees;
NULLIF(a, b)  -- returns NULL if a = b; guards divide-by-zero: x / NULLIF(y, 0)
```

**Constraints as modelling** — the reason to care isn't the syntax, it's that PK/FK reasoning *is* data modelling, and modelling is the part of DE that doesn't automate away.

| | PRIMARY KEY | UNIQUE KEY |
|---|---|---|
| NULLs | Never | Allowed (MySQL: many; SQL Server: one) |
| Per table | Exactly one | Many |
| Purpose | Row identity | Prevent duplicates |

**`INSERT ... SELECT`** — you dismissed INSERT because of `INSERT ... VALUES`. This one is the load step of every batch pipeline you will build:
```sql
INSERT INTO fact_orders (order_id, customer_id, order_date, amount)
SELECT order_id, customer_id, order_date, amount
FROM staging_orders
WHERE order_date >= '2026-01-01';
```

**DELETE / TRUNCATE / DROP**

| | DELETE | TRUNCATE | DROP |
|---|---|---|---|
| Type | DML | DDL | DDL |
| WHERE | Yes | No | — |
| Rollback | Yes | Usually no | No |
| Resets identity | No | Yes | — |
| Table survives | Yes | Yes | No |

---

## 2. Joins

INNER = matches only. LEFT = all left + matches. RIGHT = all right + matches. FULL = everything.

![JOIN types](sql_joins_diagram.png)

**The rule that matters:** NULL never matches anything, including another NULL. A foreign key pointing at a non-existent id behaves identically — it just never matches.

Your `table1`/`table2` case: table1 = 5 rows (all id=1); table2 = 5 rows id=1 + 1 row id=NULL.
- INNER = 25 (5×5), LEFT = 25, RIGHT = 26, FULL = 26. The +1 is the NULL row, preserved by RIGHT/FULL despite matching nothing.

**Self-join for hierarchies** — LEFT is mandatory, or you drop the root:
```sql
SELECT a.empname, b.empname AS manager_name, a.department
FROM emp4 a LEFT JOIN emp4 b ON a.managerid = b.empid;   -- John has managerid NULL
```
***if you take 1st table for join then also take 1st coloum for relation like ''emp4'' as a left join emp4 as b ON  a.coloum = b.coloum**

'''
SELECT 
    t1.column_name, 
    t2.column_name
FROM 
    table_name t1
[INNER | LEFT] JOIN table_name t2 
    ON t1.matching_column = t2.target_column;
'''

**Anti-join — prefer this over `NOT IN`:**
```sql
SELECT * FROM employees e
WHERE NOT EXISTS (SELECT 1 FROM departments d WHERE d.department_id = e.department_id);
```

---

## 3. Window functions

Aggregates collapse rows. Windows keep every row and add a column.

```
GROUP BY → one row per group
OVER()   → every row survives
```

**Ranking**

| name | salary | ROW_NUMBER | RANK | DENSE_RANK |
|---|---|---|---|---|
| Alice | 5000 | 1 | 1 | 1 |
| Bob | 3000 | 2 | 2 | 2 |
| Charlie | 3000 | 3 | 2 | 2 |
| David | 2000 | 4 | 4 | 3 |
| Eve | 2000 | 5 | 4 | 3 |

**Frames — the gap in your course.** A window with `ORDER BY` and no frame clause silently defaults to `RANGE UNBOUNDED PRECEDING AND CURRENT ROW`, which lumps *all tied rows together*. `ROWS` doesn't. On the table above, a running total ordered by salary gives different answers under each. Always state the frame:

```sql
SUM(x) OVER(ORDER BY d ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)  -- running total
AVG(x) OVER(ORDER BY d ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)          -- 3-day moving avg
```

**LEAD / LAG** — partition it, or "previous" jumps between people:
```sql
SELECT *, LAG(amount,1,0) OVER(PARTITION BY salesperson ORDER BY transaction_date) AS prev_amount
FROM sales1;
```
Args: `(column, offset, default_when_no_row)`.

Also exist, never demonstrated in your course: `NTILE(n)`, `FIRST_VALUE`, `LAST_VALUE`.

---

## 4. Interview patterns — the ones that repeat

**Nth highest, overall / per group**
```sql
WITH cte AS (SELECT *, ROW_NUMBER() OVER(PARTITION BY department ORDER BY salary DESC) rn FROM emp)
SELECT * FROM cte WHERE rn = 2;
```
Drop the PARTITION for overall. Change `DESC`→`ASC` for lowest. `rn IN (1,2)` for top-2.

**Duplicates** — `rn > 1`, never `rn = 2` (that only catches the second copy of a thing appearing 3+ times):
```sql
WITH cte AS (SELECT *, ROW_NUMBER() OVER(PARTITION BY employee_id ORDER BY employee_id) rn FROM employee)
SELECT * FROM cte WHERE rn > 1;
```
To *delete* them, same CTE, then `DELETE FROM cte WHERE rn > 1;`

**Top earner per group — the row, not the number.** `MAX(salary) GROUP BY position` gives you the figure and nothing else. The follow-up "who is it?" needs:
```sql
WITH cte AS (SELECT *, ROW_NUMBER() OVER(PARTITION BY position ORDER BY salary DESC) rn FROM employee)
SELECT * FROM cte WHERE rn = 1;
```

**Conditional aggregation** — the pivot workhorse. Underused in your course, appears everywhere in real work:
```sql
SELECT order_date,
  SUM(CASE WHEN order_date = first_order THEN 1 ELSE 0 END) AS new_customers,
  SUM(CASE WHEN order_date <> first_order THEN 1 ELSE 0 END) AS repeat_customers
FROM ... GROUP BY order_date;
```

**New vs repeat customer** — anchor per entity, join back, compare. This shape recurs constantly:
```sql
WITH first_visit AS (
  SELECT customer_id, MIN(order_date) AS first_order FROM customer_orders GROUP BY customer_id
)
SELECT a.order_date,
  SUM(CASE WHEN a.order_date = b.first_order THEN 1 ELSE 0 END) AS new_customers,
  SUM(CASE WHEN a.order_date <> b.first_order THEN 1 ELSE 0 END) AS repeat_customers
FROM customer_orders a JOIN first_visit b ON a.customer_id = b.customer_id
GROUP BY a.order_date;
```

**Fill NULL with last non-NULL (gaps & islands)** — genuinely advanced; worth having memorised:
```sql
WITH cte AS (
  SELECT *, ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) rn,
    CASE WHEN brand_name IS NULL THEN 0 ELSE 1 END AS has_value
  FROM chocolate_brands
),
cte1 AS (SELECT *, SUM(has_value) OVER(ORDER BY rn) AS grp FROM cte)
SELECT chocolate_name, brand_name, MAX(brand_name) OVER(PARTITION BY grp) AS filled
FROM cte1;
```
Each non-NULL bumps the running sum, creating a group id that holds until the next real value. MAX over that group carries it forward.

**WHERE vs HAVING** — WHERE filters rows pre-grouping and cannot see aggregates. HAVING filters groups post-aggregation and is the only one that can.

**UNION vs UNION ALL** — UNION dedups (slower); UNION ALL keeps everything. UNION matches columns **by position, not name** — types must line up.

---

## 5. Recursive CTE — missing from your course, you need it

Your `emp4` manager table is exactly the setup this exists for. Also: date spines to fill missing days.

```sql
WITH RECURSIVE org AS (
  SELECT empid, empname, managerid, 1 AS lvl
  FROM emp4 WHERE managerid IS NULL          -- anchor: the root
  UNION ALL
  SELECT e.empid, e.empname, e.managerid, o.lvl + 1
  FROM emp4 e JOIN org o ON e.managerid = o.empid   -- recursive step
)
SELECT * FROM org;
```
`RECURSIVE` keyword: required in MySQL/Postgres, omitted in T-SQL. Always have a termination condition or it runs away.

---

## 6. Views / Procedures / Triggers

**View** — stores a query, not data. Hides complexity, restricts columns, always current. **No performance benefit** — a view over a slow query is still slow. Identical syntax in both dialects:
```sql
CREATE VIEW emp_info AS SELECT employee_id, department_id, salary FROM employees;
DROP VIEW emp_info;
```

**Procedure vs Function**

| | Procedure | Function |
|---|---|---|
| Must return | No | Yes, exactly one |
| Can modify data | Yes | Generally no |
| Usable inside SELECT | No | Yes |
| Invoked by | `CALL` / `EXEC` | Inline |

MySQL procedure:
```sql
DELIMITER //
CREATE PROCEDURE emp_sp1(IN dept_id INT)
BEGIN SELECT * FROM employees WHERE department_id = dept_id; END //
DELIMITER ;
CALL emp_sp1(2);
```

**Trigger** (MySQL, AFTER DELETE → audit backup). Backup table must exist first:
```sql
DELIMITER //
CREATE TRIGGER employee_delete AFTER DELETE ON Employee
FOR EACH ROW
BEGIN
  INSERT INTO Backup_Employee (employee_id, employee_name, department_id, salary, deleted_at)
  VALUES (OLD.employee_id, OLD.employee_name, OLD.department_id, OLD.salary, NOW());
END //
DELIMITER ;
```

---

## 7. DE-specific SQL your course never taught

This is the part that separates DE from analyst. Learn each when a project forces it — not before.

**Data quality checks** — directly relevant to Olist:
```sql
SELECT COUNT(*) AS total,
  SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer,
  COUNT(DISTINCT order_id) AS distinct_orders,
  COUNT(*) - COUNT(DISTINCT order_id) AS dupe_orders
FROM staging_orders;
```

**Idempotent reload** — delete-then-insert the partition, so a rerun doesn't double-load:
```sql
DELETE FROM fact_orders WHERE order_date = '2026-07-18';
INSERT INTO fact_orders SELECT ... FROM staging WHERE order_date = '2026-07-18';
```

**SCD Type 2 sketch** — close the old row, open a new one:
```sql
UPDATE dim_customer SET end_date = CURRENT_DATE, is_current = 0
WHERE customer_id = ? AND is_current = 1;
INSERT INTO dim_customer (customer_id, attrs..., start_date, end_date, is_current)
VALUES (?, ..., CURRENT_DATE, '9999-12-31', 1);
```

**Dates beyond `NOW()`** — `DATEDIFF`, `DATE_ADD`, truncate-to-month, generating a date spine to fill gaps.

**Indexes / execution plans** — zero coverage in your course; asked in essentially every DE interview. `EXPLAIN <query>` in MySQL. Know scan vs seek, and why a function wrapped around an indexed column (`WHERE YEAR(d) = 2026`) kills the index.

**Also worth knowing:** `INTERSECT` / `EXCEPT`; `GROUPING SETS` / `ROLLUP` / `CUBE`; transactions and isolation levels.

---

## 8. Traps in your own course files

These are bugs in the source material — if you re-read the originals, don't memorise them.

| Where | Trap |
|---|---|
| "2nd highest salary" | Comment says 2nd, code filters `rn = 3` |
| "Top 2 per department" | Partitions by `location`, not `department` |
| Duplicate detection | `rn = 2` works only because nothing repeats 3+ times |
| HAVING section | `WHERE SUM(salary) > 10000` — aggregates illegal in WHERE |
| LEAD/LAG demo | No `PARTITION BY salesperson` — "previous" jumps between people |
| Running total | Aliased `rn`, which reads as row-number; also no frame clause |
| JOINs section | David's `dept_id = 5` commented "no department" — it's an orphaned FK, not NULL |
| JOINs section | Table dropped *after* recreation, not before |
| UNION section | Column positions/types mismatched across branches |
| ALTER section | Comment says change to VARCHAR, code re-declares INT |
| `student1` DDL | Missing comma before `FOREIGN KEY` |
| Filtering | `ID=2OR ID=3` — missing space |
| CUSTOMERS insert | Trailing comma after final row |

---

## 9. Rote block

```
ROW_NUMBER  1,2,3,4,5     never ties
RANK        1,2,2,4       ties, then skips
DENSE_RANK  1,2,2,3       ties, no skip

Frame default with ORDER BY = RANGE (lumps ties). Say ROWS explicitly.

WHERE   pre-group, no aggregates
HAVING  post-group, aggregates ok

DELETE   rows, DML, rollback, WHERE ok
TRUNCATE all rows, DDL, resets identity
DROP     table gone

INNER only matches | LEFT all left | RIGHT all right | FULL everything
NULL never matches NULL. Orphaned FK behaves the same.
NOT IN + one NULL = zero rows. Use NOT EXISTS.

PK  one per table, never NULL
UK  many, NULL ok

DECIMAL for money, never FLOAT.
COUNT(col) skips NULL. COUNT(*) doesn't. AVG ignores NULLs in the denominator.

T-SQL → MySQL
TOP n → LIMIT n | GETDATE() → NOW() | SELECT INTO → CREATE TABLE AS SELECT
IDENTITY(1,1) → AUTO_INCREMENT | EXEC → CALL | @p → IN p
FROM DELETED → OLD.col + FOR EACH ROW
```

---

## 10. Honest status

**Intermediate.** Comfortably so — roughly 65–70% of DE interview expectation. Sections 5 and 7 are the gap between here and advanced, and neither closes by reading.

**This file is a reference, not a plan.** Your SQL is not the bottleneck. Zero portfolio projects and an open commitment to Faiz are the bottleneck. Start Olist; the date functions, conditional aggregation, `INSERT ... SELECT`, quality checks and `EXPLAIN` in §7 will all arrive on their own when the work demands them — and they'll stick, which revision doesn't.

Library, not home. Your own log data says so.
