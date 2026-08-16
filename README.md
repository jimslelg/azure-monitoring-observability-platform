# Azure Monitoring & Observability Platform

A centralized, production-grade observability platform for Azure workloads, built
entirely with Infrastructure as Code. It provisions Azure Monitor, Log Analytics,
Application Insights, managed Prometheus and Grafana, and rolls out diagnostic
settings, alert rules, dashboards, and workbooks across AKS, VMs, App Service,
SQL, Storage, and networking.

> Status: under active development — see [docs/ROADMAP.md](docs/ROADMAP.md).

## Stack

| Layer | Technology |
|---|---|
| Telemetry backend | Azure Monitor, Log Analytics, Application Insights |
| Metrics & visualization | Azure Managed Prometheus, Azure Managed Grafana, Azure Dashboards, Workbooks |
| Workloads monitored | AKS, Virtual Machines, App Service, Azure SQL, Storage, Networking |
| IaC & delivery | Terraform, Azure DevOps Pipelines |

## Repository layout

```
terraform/          Root stack + reusable modules (one module per monitoring concern)
kql/                KQL query library, organized by workload
dashboards/         Azure Dashboard ARM templates and Grafana dashboard JSON
workbooks/          Azure Monitor Workbook definitions
prometheus/         Prometheus rule groups and scrape configuration
scripts/            Diagnostic-settings automation (az CLI / PowerShell)
pipelines/          Azure DevOps pipeline definitions and reusable templates
docs/               Architecture, design decisions, runbooks, roadmap
```

## Getting started

```bash
cd terraform
terraform init -backend-config=../environments/dev.backend.hcl
terraform plan -var-file=environments/dev.tfvars
```

Authentication is OIDC workload identity federation — no client secrets are stored
in this repository or its pipelines.

## License

MIT — see [LICENSE](LICENSE).
