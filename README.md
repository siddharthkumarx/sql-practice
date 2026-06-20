<!--
SETUP (invisible on GitHub):
Open your sql-practice repo, replace README.md with this file, and commit.
Reorganize your .sql files into the folders shown below (on GitHub web, name a new file
"01_foundations/01_select_basics.sql" and it creates the folder).
Replace [your-username] if it appears below.
-->

# SQL Practice

Every SQL concept I've worked through since April 2026, practiced in MySQL Workbench and committed session by session. This repository is both my record of progress and my own revision reference.

## Structure

```
sql-practice/
├── 01_foundations/      SELECT, WHERE, logical operators, NULL handling,
│                        ORDER BY, aggregate functions, GROUP BY, HAVING
├── 02_intermediate/     All JOIN types, FULL JOIN via UNION, subqueries,
│                        CTEs, window functions, string and date functions,
│                        casting, CASE, UNION
├── 03_advanced/         Indexes, EXPLAIN and query optimization, transactions
│                        and ACID, views, stored procedures (in progress)
├── hackerrank/          Solved HackerRank problems with notes
└── datasets/            Schema and sample-data scripts for the local practice_db
```

## Topics

| Phase | Topics | Status |
|-------|--------|--------|
| Foundations | SELECT, WHERE, logical operators, NULL handling, ORDER BY, aggregates, GROUP BY, HAVING | Complete |
| Intermediate | All JOIN types, the fan-out trap, subqueries, CTEs, window functions, string/date functions, casting, CASE, UNION | Complete |
| Advanced | Indexes, EXPLAIN and query optimization, transactions and ACID, views, stored procedures | In progress |

## How I practice

Every query is written and verified against a local MySQL database before it's committed, alongside HackerRank problems. The files include comments on the traps worth remembering — for example, that MySQL sorts NULLs first under ASC, that WHERE filters the joined result rather than the original table, and that one-to-many joins can silently inflate COUNT and AVG.

This is a learning repository. Earlier files are simpler than later ones by design; the commit history shows the progression.

---

More of what I'm building: [github.com/[your-username]](https://github.com/siddharthkumarx)
