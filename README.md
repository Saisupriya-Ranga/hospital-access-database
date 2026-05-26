# Hospital Access Database — Rural Healthcare Analytics

Relational database project analyzing rural healthcare access gaps 
across Texas counties, motivated by real-world hospital closure data.

## Research Question
Which is the nearest open hospital for each Texas county, 
and how do rural communities differ in healthcare accessibility?

## Dataset
- **Source:** Kaggle Hospital Data + U.S. Census Bureau County Data
- **Motivation:** Texas Tribune rural hospital closure reporting
- **Entities:** Hospital, County, Hospital_County_Distance (bridge table)

## Tools & Technologies
- MySQL
- SQL Server Management Studio (SSMS)
- ERD Design
- Query Optimization (EXPLAIN plans, SHOW PROFILE)

## Database Design
- **Normalization:** 3NF — eliminated redundancy and update anomalies
- **Schema:** 3 entities with Hospital_County_Distance as bridge table
- **Relationships:** Many-to-many between Hospital and County

## Key Implementation
- Complex SQL query to identify nearest open hospital per county
- Uses JOIN, GROUP BY, MIN(), and subqueries
- 3 strategic indexes created:
  - `idx_status` on Hospital(Status)
  - `idx_hospital` on Hospital ID
  - `idx_county_distance` composite index

## Performance Results
| Query | Before Indexing | After Indexing | Improvement |
|---|---|---|---|
| Nearest hospital per county | 1.73 seconds | 0.05 seconds | **32x faster** |

## Security Implementation
Role-based access control following Principle of Least Privilege:

| Role | Permissions |
|---|---|
| analyst | SELECT only |
| manager | SELECT, INSERT, UPDATE |
| admin | Full access |
| test_user | Limited SELECT |

## Backup Strategy
- **Full backup** — weekly
- **Incremental backup** — daily
- **Recovery Time Objective (RTO):** 4 hours

## Grade
**48/50** ✅

## ERD
![ERD Diagram](erd_diagram.png)
