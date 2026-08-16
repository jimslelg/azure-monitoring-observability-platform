# Alert Reference

Severity → routing: **0-1** page on-call (`ag-*-critical`), **2-3** platform
team (`ag-*-platform`), **4** informational (`ag-*-info`). All rules
auto-mitigate. Names below use the `amop-prod` prefix as the example.

## Sev 1 — pages on-call

| Rule | Signal | Condition | Runbook |
|---|---|---|---|
| `alert-amop-prod-vm-heartbeat-missing` | KQL / Heartbeat | No heartbeat 10 min | [vm-down](runbooks/vm-down.md) |
| `KubeNodeNotReady` | Prometheus | Ready=false 10 min | [aks-node-notready](runbooks/aks-node-notready.md) |
| `alert-amop-prod-app-http-5xx` | Metric / Http5xx | > 10 in 5 min | [app-5xx-spike](runbooks/app-5xx-spike.md) |
| `alert-amop-prod-sql-deadlocks` | Metric / deadlock | > 0 in 15 min | — |
| `alert-amop-prod-storage-availability` | Metric / Availability | < 99.9% avg 15 min | — |
| `alert-amop-prod-agw-unhealthy-hosts` | Metric / UnhealthyHostCount | > 0 avg 5 min | — |

## Sev 2-3 — platform team

| Rule | Signal | Condition |
|---|---|---|
| `alert-amop-prod-vm-cpu-high` | Metric | CPU > 90% avg 15 min |
| `alert-amop-prod-vm-memory-low` | Metric | Available < 512 MB avg 15 min |
| `alert-amop-prod-vm-disk-space-low` | KQL | Volume < 10% free |
| `KubePodCrashLooping` | Prometheus | > 3 restarts / 15 min |
| `KubeContainerOOMKilled` | Prometheus | OOMKill seen |
| `KubePersistentVolumeFillingUp` | Prometheus | PV < 10% free 15 min |
| `alert-amop-prod-aks-node-cpu` / `-node-memory` | Metric | > 85% / > 90% avg 15 min |
| `alert-amop-prod-aks-pods-failed` | Metric | Failed-phase pods > 0 |
| `alert-amop-prod-app-response-time` | Metric | > 3 s avg 15 min |
| `alert-amop-prod-plan-cpu-high` / `-plan-memory-high` | Metric | > 85% avg 15 min |
| `alert-amop-prod-sql-cpu-high` / `-sql-storage-high` / `-sql-dtu-high` | Metric | > 90% / > 85% / > 90% |
| `alert-amop-prod-storage-latency` / `-storage-throttling` / `-storage-capacity` | Metric | > 1 s / throttled responses / > threshold |
| `alert-amop-prod-agw-failed-requests` | Metric | > 25 in 5 min |
| `alert-amop-prod-net-denied-spike` | KQL | > 1000 denied flows / 15 min |
| `alert-amop-prod-service-health` | Activity log | Incident / security advisory |
| `appi-*-failure-anomalies` | Smart detection | Anomalous failure rate |

## Sev 4 — informational

| Rule | Signal | Condition |
|---|---|---|
| `alert-amop-prod-aks-container-errors` | KQL | > 100 stderr lines / 15 min per workload |

## Tuning

Thresholds are module defaults, deliberately conservative. Change them in the
workload module (they apply platform-wide) or, when one resource legitimately
differs, add a dedicated rule via the `alerts` module rather than widening the
default for everyone.
