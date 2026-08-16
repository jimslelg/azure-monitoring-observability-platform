# Monitoring Strategy

## What gets monitored, and how

| Workload | Logs | Metrics | Baseline alerts |
|---|---|---|---|
| VMs | Syslog (auth/daemon/kern ≥ Warning), Windows System/Application ≥ Warning + logon events | AMA perf counters @60 s | Heartbeat missing (Sev1), CPU > 90%, memory < 512 MB, disk < 10% free |
| AKS | Container Insights (ContainerLogV2), KubeEvents | Managed Prometheus (kubelet, cAdvisor, kube-state, node-exporter @30 s) | NodeNotReady (Sev1), crash loops, OOMKills, PV filling, node CPU/memory, failed pods |
| App Service | Full diagnostic categories + App Insights telemetry | Platform metrics | HTTP 5xx > 10/5 min (Sev1), response time > 3 s, plan CPU/memory > 85% |
| Azure SQL | Query Store runtime/wait stats, Errors, Blocks, Deadlocks, Timeouts | Platform metrics | Deadlocks (Sev1), CPU > 90%, storage > 85%, DTU (toggleable) |
| Storage | Blob-service transaction logs | Account metrics | Availability < 99.9% (Sev1), E2E latency > 1 s, capacity, throttling |
| Network | NSG flow logs v2 + Traffic Analytics, gateway/firewall diagnostics | Platform metrics | AGW unhealthy hosts (Sev1), failed requests, denied-flow spikes |
| Subscription | Activity log | — | Service Health incidents and security advisories |

## Alerting philosophy

1. **A page means "act now".** Only Sev0/Sev1 reach the critical action group,
   and each one has a runbook in `docs/runbooks/`. If an alert pages twice
   without action being taken, it gets retuned or demoted.
2. **Symptoms over causes for paging; causes for context.** The page is
   "availability dropped" / "no heartbeat"; the workbooks and KQL library
   answer *why*.
3. **Auto-mitigation on everywhere.** Alerts resolve themselves when the
   condition clears; stale firing alerts erode trust faster than noise.
4. **Common alert schema on every receiver,** so downstream automation parses
   one payload shape regardless of alert type.
5. **Noise is reviewed monthly** with `kql/platform/alert-noise.kql` — volume
   by rule, actioned vs ignored.

## Cost control

- Dev workspaces: 30-day retention, hard daily cap (5 GB). Prod: 180-day
  retention, no cap — dropping telemetry mid-incident costs more than overage.
- The Cost & Ingestion workbook is the monthly review: top tables must map to
  a deliberate collection decision (DCR counter list, log level floor,
  Prometheus keep-lists in `prometheus/ama-metrics-settings-configmap.yaml`).
- Collection is tuned at the source (DCR sampling, syslog level floors,
  Container Insights 1-minute interval, Prometheus scrape keep-lists), not by
  deleting data after ingestion.

## Onboarding a new workload

1. Add the resource IDs to the environment tfvars (`monitored_*` maps).
2. `terraform plan` — diagnostics and the baseline alert pack appear; apply
   through the pipeline.
3. For resource types the platform doesn't model yet, run
   `scripts/enable-diagnostics.sh` for immediate coverage, then promote the
   type into a proper module.
4. The weekly coverage pipeline (`Get-DiagnosticCoverage.ps1`) fails red while
   anything in the curated type list remains uncovered.
