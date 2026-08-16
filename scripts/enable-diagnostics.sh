#!/usr/bin/env bash
#
# enable-diagnostics.sh
#
# Sweep a subscription (or one resource group) for resources missing a
# diagnostic setting and attach one that routes allLogs + AllMetrics to the
# central Log Analytics workspace. Terraform owns diagnostics for resources it
# manages; this script closes the gap for everything created outside IaC and
# is safe to run repeatedly (existing settings are left untouched).
#
# Usage:
#   ./enable-diagnostics.sh -w <workspace-resource-id> [options]
#
# Options:
#   -w  Resource ID of the central Log Analytics workspace   (required)
#   -g  Limit the sweep to one resource group
#   -t  Resource type to include (repeatable; default: a curated set)
#   -n  Diagnostic setting name (default: diag-to-central-law)
#   -d  Dry run — report what would change, write nothing
#   -h  Help
#
# Exit codes: 0 ok, 1 general error, 2 not logged in, 3 completed with
# per-resource failures, 4 bad arguments.

set -euo pipefail

SETTING_NAME="diag-to-central-law"
WORKSPACE_ID=""
RESOURCE_GROUP=""
DRY_RUN=false
declare -a RESOURCE_TYPES=()

DEFAULT_TYPES=(
  "Microsoft.Web/sites"
  "Microsoft.Web/serverfarms"
  "Microsoft.Sql/servers/databases"
  "Microsoft.KeyVault/vaults"
  "Microsoft.ContainerService/managedClusters"
  "Microsoft.Network/applicationGateways"
  "Microsoft.Network/azureFirewalls"
  "Microsoft.Network/loadBalancers"
  "Microsoft.ServiceBus/namespaces"
  "Microsoft.EventHub/namespaces"
)

usage() { grep '^#' "$0" | cut -c 3-; }

log()  { printf '%s %s\n' "$(date -u +%H:%M:%S)" "$*"; }
warn() { printf '%s WARN %s\n' "$(date -u +%H:%M:%S)" "$*" >&2; }

while getopts ":w:g:t:n:dh" opt; do
  case "$opt" in
    w) WORKSPACE_ID="$OPTARG" ;;
    g) RESOURCE_GROUP="$OPTARG" ;;
    t) RESOURCE_TYPES+=("$OPTARG") ;;
    n) SETTING_NAME="$OPTARG" ;;
    d) DRY_RUN=true ;;
    h) usage; exit 0 ;;
    *) usage; exit 4 ;;
  esac
done

if [[ -z "$WORKSPACE_ID" ]]; then
  warn "workspace resource ID (-w) is required"
  usage
  exit 4
fi

if [[ ${#RESOURCE_TYPES[@]} -eq 0 ]]; then
  RESOURCE_TYPES=("${DEFAULT_TYPES[@]}")
fi

az account show --only-show-errors >/dev/null 2>&1 || { warn "not logged in — run az login"; exit 2; }

# Build the resource list once. --resource-type only supports one type per
# call, so filter a single listing by type locally instead.
list_args=(resource list --only-show-errors -o json)
if [[ -n "$RESOURCE_GROUP" ]]; then
  list_args+=(--resource-group "$RESOURCE_GROUP")
fi
all_resources="$(az "${list_args[@]}")"

type_filter="$(printf '%s\n' "${RESOURCE_TYPES[@]}" | jq -R . | jq -s .)"
resources="$(jq --argjson types "$type_filter" \
  '[.[] | select(.type as $t | $types | map(ascii_downcase) | index($t | ascii_downcase))]' \
  <<<"$all_resources")"

total="$(jq length <<<"$resources")"
log "found $total candidate resource(s) across ${#RESOURCE_TYPES[@]} type(s)"

created=0 skipped=0 failed=0

while IFS= read -r resource_id; do
  [[ -z "$resource_id" ]] && continue

  existing="$(az monitor diagnostic-settings list --resource "$resource_id" \
    --only-show-errors --query "value[?name=='$SETTING_NAME'] | length(@)" -o tsv 2>/dev/null || echo 0)"
  if [[ "$existing" != "0" ]]; then
    skipped=$((skipped + 1))
    continue
  fi

  # Discover what this resource can emit and request everything: the allLogs
  # category group when supported, explicit categories otherwise, and metrics.
  categories="$(az monitor diagnostic-settings categories list --resource "$resource_id" \
    --only-show-errors -o json 2>/dev/null || echo '{"value":[]}')"

  logs_json="$(jq '[.value[] | select(.categoryType == "Logs")] |
    if any(.[]; .categoryGroups != null and (.categoryGroups | index("allLogs"))) then
      [{categoryGroup: "allLogs", enabled: true}]
    else
      [.[] | {category: .name, enabled: true}]
    end' <<<"$categories")"

  metrics_json="$(jq '[.value[] | select(.categoryType == "Metrics") | {category: .name, enabled: true}]' <<<"$categories")"

  if [[ "$logs_json" == "[]" && "$metrics_json" == "[]" ]]; then
    warn "no diagnostic categories reported for $resource_id — skipping"
    skipped=$((skipped + 1))
    continue
  fi

  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN would create '$SETTING_NAME' on $resource_id"
    created=$((created + 1))
    continue
  fi

  if az monitor diagnostic-settings create \
      --name "$SETTING_NAME" \
      --resource "$resource_id" \
      --workspace "$WORKSPACE_ID" \
      --logs "$logs_json" \
      --metrics "$metrics_json" \
      --only-show-errors >/dev/null; then
    log "created '$SETTING_NAME' on $resource_id"
    created=$((created + 1))
  else
    warn "failed to create diagnostic setting on $resource_id"
    failed=$((failed + 1))
  fi
done < <(jq -r '.[].id' <<<"$resources")

log "done: created=$created skipped=$skipped failed=$failed (dry-run=$DRY_RUN)"
[[ "$failed" -gt 0 ]] && exit 3
exit 0
