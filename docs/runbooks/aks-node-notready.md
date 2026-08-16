# Runbook: AKS Node NotReady (Sev 1)

**Alert:** Prometheus `KubeNodeNotReady` — a node has reported NotReady for
10+ minutes. Workloads on it are being evicted or are unschedulable.

## Triage (first 5 minutes)

1. Confirm and scope:
   ```bash
   kubectl get nodes -o wide
   kubectl describe node <node> | sed -n '/Conditions:/,/Addresses:/p'
   ```
   One node → node problem. Several in one pool → pool/upgrade problem. All →
   control plane or network; check Service Health and AKS cluster status.
2. Check cluster capacity: are the evicted pods rescheduling, or Pending?
   `kubectl get pods -A --field-selector status.phase=Pending`
3. Check for an in-flight cluster/nodepool upgrade or scale event in the
   activity log — surge upgrades make nodes NotReady on purpose.

## Diagnosis

| Condition flag | Meaning | Action |
|---|---|---|
| `MemoryPressure` / `DiskPressure` | Node exhausted | Find the hog: `kql/aks/node-pressure.kql`, check for missing resource limits |
| `NetworkUnavailable` | CNI/subnet issue | Check subnet IP exhaustion, recent network changes |
| Kubelet stopped posting | VM-level failure | Treat as VM-down on the underlying scale-set instance |

## Recovery

- Cordon + drain if the node is half-alive: `kubectl drain <node>
  --ignore-daemonsets --delete-emptydir-data`
- Reimage via the VMSS: `az aks nodepool upgrade --node-image-only` or delete
  the instance and let the pool replace it.
- Confirm: node Ready, Pending pods scheduled, `KubePodCrashLooping` quiet.

## Post-incident

Repeated pressure evictions mean the pool is undersized or limits are absent —
raise with the workload team; the namespace CPU/memory Grafana panels show who
grew.
