#!/usr/bin/env bash

set -e

echo "Cleaning up arkollama-k3s project..."

# Force k3s kubeconfig if it exists (to avoid TLS errors)
K3S_CONFIG="$HOME/.kube/arkollama-k3s.config"
if [ -f "$K3S_CONFIG" ]; then
    export KUBECONFIG="$K3S_CONFIG"
    echo "Using k3s config: $KUBECONFIG"
fi

# Remove all agents (using the management script) - but only if kubectl can connect
if [ -f "scripts/manage-agents.sh" ]; then
    if kubectl get nodes &>/dev/null; then
        ./scripts/manage-agents.sh delete
    else
        echo "Cluster not reachable, skipping agent deletion."
    fi
fi

# Uninstall ARK (only if the cluster is reachable)
if command -v ark &> /dev/null; then
    if kubectl get nodes &>/dev/null; then
        echo "Uninstalling ARK..."
        ark uninstall --yes || true
    else
        echo "Cluster not reachable, skipping ARK uninstall."
    fi
fi

# Remove namespaces even if the cluster is not fully reachable? 
# kubectl may still work for namespace deletion if the API server is up but TLS fails.
# We'll try anyway, ignoring errors.
kubectl delete namespace ollama-system --ignore-not-found=true 2>/dev/null || true
kubectl delete namespace ark-system --ignore-not-found=true 2>/dev/null || true

echo "Cleanup done."
echo "To fully remove k3s, run: sudo /usr/local/bin/k3s-uninstall.sh"
