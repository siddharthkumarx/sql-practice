<!--
SETUP (invisible on GitHub):
1. Open your existing sql-practice repo → README.md → pencil icon → replace everything with this file → Commit.
2. Reorganize your .sql files into the folder structure below (you can do this on GitHub web:
   when editing/creating a file, type "01_foundations/01_select_basics.sql" as the filename — GitHub creates the folder).
3. Replace [YOUR-USERNAME] if it appears anywhere.
-->

# 🗄️ SQL Practice — Data Engineering Foundations

Every SQL concept I've learned since **April 2026**, practiced hands-on in MySQL Workbench and committed here session by session. This repo is both my proof of work and my personal revision reference.

## 📁 Structure

```
sql-practice/
├── 01_foundations/      # SELECT, WHERE, AND/OR/NOT, NULL handling, ORDER BY,
│                        # aggregate functions, GROUP BY, HAVING
├── 02_intermediate/     # INNER/LEFT/RIGHT/CROSS/SELF joins, FULL JOIN via UNION,
│                        # subqueries, CTEs, window functions, string & date
│                        # functions, casting, CASE, UNION
├── 03_advanced/         # Indexes, EXPLAIN & query optimization, transactions
│                        # & ACID, views, stored procedures (in progress)
├── hackerrank/          # Solved HackerRank SQL problems with my notes
└── datasets/            # Schema + sample data scripts for my local practice_db
                         # (employees, products tables)
```

## ✅ Topics covered

| Phase | Topics | Status |
|---|---|---|
| **1 — Foundations** | SELECT · WHERE · logical operators · NULL handling · ORDER BY · aggregates · GROUP BY · HAVING | ✅ Complete |
| **2 — Intermediate** | All JOIN types · the duplicate-row fan-out trap · subqueries · CTEs · window functions · string/date functions · casting · CASE · UNION | ✅ Complete |
| **3 — Advanced** | Indexes ✅ · EXPLAIN & query optimization ✅ · transactions & ACID 🔄 · views, stored procedures, pipeline patterns 🔜 | 🔄 In progress |

## 🧪 How I practice

- Local MySQL database (`practice_db`) in **MySQL Workbench** — I run and verify every query before committing it
- **HackerRank** problems alongside structured lessons
- Each `.sql` file contains runnable queries plus comments on the traps I hit (e.g., MySQL sorts `NULL`s **first** in `ASC`; `WHERE` filters the *joined* table, not the original one; one-to-many joins silently inflating `COUNT()` and `AVG()`)

## ⚠️ Honest note

This is a **learning repo**. Early files are simpler than later ones — that's the point. Watch the commit history to see the progression.

---

📂 More about me and what I'm building: [github.com/siddharthkumarx]](https://github.com/siddharthkumarx)
