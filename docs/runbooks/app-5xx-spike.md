# Runbook: App Service HTTP 5xx Spike (Sev 1)

**Alert:** `alert-<env>-app-http-5xx` — more than 10 server errors in 5 minutes.

## Triage (first 5 minutes)

1. Scope it: one operation or all of them?
   Run `kql/app-service/request-failures.kql` — a single failing operation is
   a code path; everything failing is platform, dependency, or deploy.
2. Check for a deployment in the last 30 minutes (App Service deployment
   center / pipeline history). If yes: **roll back first, diagnose after.**
3. Check dependencies: `kql/app-service/dependency-failures.kql` — SQL or a
   downstream API erroring explains cascading 5xx.

## Diagnosis

| Pattern | Likely cause | Action |
|---|---|---|
| Started at deploy time | Bad release | Slot swap back / redeploy previous |
| One dependency failing | Downstream outage | Check that service's alerts; enable circuit breaker if available |
| 502/503 only | Plan exhaustion or restarts | Check plan CPU/memory alerts, `AppServicePlatformLogs` for recycle events |
| Gradual rise with traffic | Capacity | Scale out the plan; latency percentiles (`latency-percentiles.kql`) confirm saturation |
| Exceptions of one type | Code bug | `kql/app-service/exceptions-by-type.kql`, hand ProblemId to the owning team |

## Recovery confirmation

5xx rate returns to baseline and the availability web test
(`webtest-inventory-api`) goes green. Alert auto-mitigates in one window.

## Post-incident

Record whether the 3 s / 10-error thresholds gave useful lead time; tune in
`terraform/modules/app-service-monitoring/main.tf` if not.
