# Roadmap

## v1 (complete)

- Central Log Analytics + workspace-based Application Insights + three-tier
  action groups
- Workload modules: VM (AMA/DCR), App Service, SQL, Storage, Network
- AKS: Container Insights + managed Prometheus + managed rule groups
- Azure Managed Grafana with two dashboards; workbooks; portal dashboard
- KQL library (18 queries), alert reference, runbooks
- Diagnostic-settings automation (sweep script + weekly coverage report)
- OIDC-only delivery pipeline with saved-plan applies

## v1.x — hardening

- [ ] **AMPLS (Azure Monitor Private Link Scope)** — private ingestion/query,
      then flip `internet_ingestion_enabled/internet_query_enabled` to false
- [ ] **Azure Policy DeployIfNotExists** for diagnostic settings, replacing
      the sweep script as the primary gap-closer (script stays for reporting)
- [ ] **Alert processing rules** — maintenance-window suppression instead of
      disabling rules by hand
- [ ] **Grafana dashboard provisioning** via `grafana_dashboard` Terraform
      provider so the JSON in `dashboards/grafana/` deploys automatically
- [ ] **Basic/auxiliary table tiers** for high-volume verbose tables
      (ContainerLogV2) once query patterns are confirmed

## v2 — candidates

- [ ] SLO layer: availability/latency SLOs with burn-rate alerts (multi-window)
      replacing several static thresholds
- [ ] Distributed tracing: OpenTelemetry collector on AKS exporting to
      Application Insights
- [ ] Cost anomaly detection: scheduled query alert on `Usage` deviations
- [ ] Multi-region: paired-region workspace strategy and Grafana with both
      Prometheus datasources
- [ ] Synthetic monitoring beyond HTTP checks (Playwright availability tests)
- [ ] Export pipeline: continuous export of security-relevant tables to
      immutable storage for retention beyond 730 days
