#!/usr/bin/env bash

set -e

echo "🔧 Installing k3s..."
curl -sfL https://get.k3s.io | sh -s - --disable=traefik --write-kubeconfig-mode 644

mkdir -p ~/.kube
K3S_CONFIG="$HOME/.kube/arkollama-k3s.config"
sudo k3s kubectl config view --raw | tee "$K3S_CONFIG" > /dev/null
chmod 600 "$K3S_CONFIG"

echo "✅ k3s installed."
echo "👉 To use this cluster, run: export KUBECONFIG=\"$K3S_CONFIG\""
echo "   (or merge it with your existing config by exporting both: export KUBECONFIG=\"$HOME/.kube/config:$K3S_CONFIG\")"
echo ""

KUBECONFIG="$K3S_CONFIG" kubectl get nodes
