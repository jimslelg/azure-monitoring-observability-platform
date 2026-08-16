# Runbook: VM Heartbeat Missing (Sev 1)

**Alert:** `alert-<env>-vm-heartbeat-missing` — no heartbeat for 10+ minutes.
The host is down, unreachable, or the Azure Monitor Agent stopped.

## Triage (first 5 minutes)

1. Identify the machine(s): the alert's common schema payload carries
   `_ResourceId`; or run `kql/vm/heartbeat-gaps.kql`.
2. Check whether the VM is running:
   ```bash
   az vm get-instance-view -g <rg> -n <vm> --query instanceView.statuses
   ```
3. Cross-check Service Health — a platform incident in the region means this
   is not yours to fix; link the alert to the tracking incident.

## Diagnosis

| Observation | Likely cause | Action |
|---|---|---|
| VM deallocated/stopped | Planned or runaway automation | Check activity log for the stop event and its caller |
| VM running, no heartbeat | AMA crashed or DCR association removed | Restart the agent extension; verify DCRA with `az monitor data-collection rule association list --resource <vm-id>` |
| VM running, boot diagnostics show kernel panic / BSOD | Guest OS failure | Redeploy or restore; escalate to workload owner |
| Whole subnet silent | NSG/UDR/DNS change | Check `kql/network/denied-flows.kql` and recent network deployments |

## Recovery

- Agent restart: `az vm extension set` (AzureMonitorLinuxAgent /
  AzureMonitorWindowsAgent) or reboot the VM in agreement with the owner.
- Confirm recovery: heartbeat returns within ~2 minutes; the alert
  auto-mitigates.

## Post-incident

If the cause was an unmanaged change (agent removed, DCRA deleted), file the
gap: the resource should be in `monitored_virtual_machines` so Terraform
re-creates the association on the next apply.
