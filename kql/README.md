# KQL Query Library

Curated queries for the central Log Analytics workspace, organized by workload.
Each file states its purpose and source tables in a header comment. Queries are
copy-paste ready in the Logs blade and are the same ones referenced by alert
rules and workbooks — fix a query here first, then propagate.

| Folder | Focus |
|---|---|
| `aks/` | Pod restarts, container errors, node pressure, warning events |
| `vm/` | Heartbeat gaps, disk trends, Windows/Linux auth failures |
| `app-service/` | Request failures, latency percentiles, dependencies, exceptions |
| `sql/` | Slow queries, deadlocks, blocking and timeouts |
| `storage/` | Failing operations, anonymous/SAS access audit |
| `network/` | Denied flows, top talkers (Traffic Analytics) |
| `platform/` | Ingestion cost, alert noise, agent coverage |

Conventions: explicit time filters in every query (alert rules override them
with their own window), `_ResourceId` preserved wherever a query may back a
resource-centric alert, `take`/`top` caps on exploratory queries.
