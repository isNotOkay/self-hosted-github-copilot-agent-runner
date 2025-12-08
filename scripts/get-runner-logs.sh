#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="actions-runner-system"
PATTERN="copilot-agent-runners"

echo "🔍 Collecting logs from ALL containers in runner pods in namespace: ${NAMESPACE}"
echo

# Get all runner pod names matching the pattern (snapshot in time)
PODS=$(kubectl get pods -n "${NAMESPACE}" \
  | awk -v pat="${PATTERN}" '$1 ~ pat {print $1}')

if [ -z "${PODS}" ]; then
  echo "❌ No pods matching '${PATTERN}' found in namespace '${NAMESPACE}'."
  exit 1
fi

for POD in ${PODS}; do
  echo "============================================================"
  echo "📦 Pod: ${POD}"
  echo "============================================================"

  # If the pod disappeared between listing and now, skip it
  if ! kubectl get pod "${POD}" -n "${NAMESPACE}" &>/dev/null; then
    echo "⚠️  Pod ${POD} no longer exists, skipping."
    echo
    continue
  fi

  # List containers in the pod
  CONTAINERS=$(kubectl get pod "${POD}" -n "${NAMESPACE}" \
    -o jsonpath='{.spec.containers[*].name}')

  echo "Containers: ${CONTAINERS}"
  echo

  for C in ${CONTAINERS}; do
    echo "➡️  Logs for container '${C}' (current)..."
    if ! kubectl logs -n "${NAMESPACE}" "${POD}" -c "${C}" --tail=60; then
      echo "⚠️  Current logs unavailable for '${C}', trying previous..."
      if ! kubectl logs -n "${NAMESPACE}" "${POD}" -c "${C}" --previous --tail=60; then
        echo "❌ No logs found for container '${C}' in pod ${POD}."
      fi
    fi
    echo
  done
done
