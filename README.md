# Azure Monitoring & Observability Platform

A centralized, production-grade observability platform for Azure workloads,
built entirely with Infrastructure as Code. One Terraform stack provisions the
telemetry backends (Log Analytics, Application Insights, managed Prometheus),
notification routing, dashboards, and workbooks — then attaches diagnostics
and an opinionated alert pack to every onboarded VM, AKS cluster, App Service,
SQL database, storage account, and network resource.

## Highlights

- **Two backends, no silos** — logs and events in Log Analytics, Prometheus
  metrics in an Azure Monitor workspace; Grafana, workbooks, and alerts read
  from those alone.
- **Onboarding is a tfvars edit** — add a resource ID to a `monitored_*` map
  and the next apply attaches diagnostics plus the workload's baseline alerts.
- **Three-tier alert routing** — Sev0-1 pages on-call, Sev2-3 emails the
  platform team, Sev4 goes to ITSM; rules reference tiers, never receivers.
- **Zero stored credentials** — OIDC workload identity federation for the
  pipeline, the Terraform backend, and the provider.
- **Everything reviewable** — dashboards, workbooks, Prometheus rules, and
  KQL live as files; portal edits come back as pull requests.

## Stack

Azure Monitor · Log Analytics · Application Insights · Azure Managed
Prometheus · Azure Managed Grafana · Workbooks · Azure Dashboards · AKS ·
Terraform · Azure DevOps Pipelines

## Repository layout

```
terraform/            Root stack; environments/ tfvars + backend configs
  modules/            13 modules — one per monitoring concern (see docs/architecture.md)
kql/                  Query library by workload (aks, vm, app-service, sql, storage, network, platform)
dashboards/
  azure/              Portal dashboard template (Terraform-deployed)
  grafana/            Grafana dashboard JSON (PromQL + Azure Monitor datasources)
workbooks/            Azure Monitor Workbooks (Terraform-deployed)
prometheus/           Metrics add-on scrape settings + native-format rules reference
scripts/              enable-diagnostics.sh sweep + Get-DiagnosticCoverage.ps1 report
pipelines/            Azure DevOps: delivery pipeline, weekly coverage report, templates
docs/                 Architecture, monitoring strategy, alert reference, runbooks, roadmap
```

## Getting started

```bash
cd terraform
terraform init -backend-config=environments/dev.backend.hcl
terraform plan -var-file=environments/dev.tfvars
```

In CI the same commands run through `pipelines/monitoring-pipeline.yml`:
static validation on every PR, then plan → apply for dev and prod on `main`,
with production approval on the ADO Environment and applies executing the
reviewed plan artifact.

## Documentation

| Doc | Contents |
|---|---|
| [Architecture](docs/architecture.md) | Telemetry-flow and alert-routing diagrams, module contract, design invariants |
| [Monitoring strategy](docs/monitoring-strategy.md) | Per-workload coverage, alerting philosophy, cost control, onboarding |
| [Alert reference](docs/alert-reference.md) | Every rule with condition, severity, and routing |
| [Runbooks](docs/runbooks/) | VM down, App Service 5xx spike, AKS node NotReady |
| [Roadmap](docs/ROADMAP.md) | Completed v1 scope and what's next |

## License

MIT — see [LICENSE](LICENSE).
