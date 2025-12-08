#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="actions-runner-system"
PATTERN="copilot-agent-runners"

echo "🔍 Collecting logs from runner pods in namespace: ${NAMESPACE}"
echo

# Get all runner pod names matching the pattern
PODS=$(kubectl get pods -n "${NAMESPACE}" \
  | awk -v pat="${PATTERN}" '$1 ~ pat {print $1}')

if [ -z "${PODS}" ]; then
  echo "❌ No pods matching '${PATTERN}' found in namespace '${NAMESPACE}'."
  exit 1
fi

for POD in ${PODS}; do
  echo "==============================================="
  echo "📦 Pod: ${POD}"
  echo "==============================================="

  echo "➡️  Trying current logs for container 'runner'..."
  if ! kubectl logs -n "${NAMESPACE}" "${POD}" -c runner --tail=80; then
    echo "⚠️  Current logs unavailable, trying previous logs..."
    if ! kubectl logs -n "${NAMESPACE}" "${POD}" -c runner --previous --tail=80; then
      echo "❌ No logs found for container 'runner' in pod ${POD}."
    fi
  fi

  echo
done
