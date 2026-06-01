#!/usr/bin/env bash

set -e

echo "📥 Checking for Helm..."
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Please install it first:"
    echo "   https://helm.sh/docs/intro/install/"
    exit 1
fi
echo "✅ Helm found."

K3S_CONFIG="$HOME/.kube/arkollama-k3s.config"
if [ -f "$K3S_CONFIG" ]; then
    export KUBECONFIG="$K3S_CONFIG"
    echo "🔧 Using k3s config: $KUBECONFIG"
fi

echo "📥 Installing ARK CLI..."
npm install -g @agents-at-scale/ark@latest

echo "🔧 Installing ARK components into the cluster..."
# The install command will also check for other dependencies
ark install

echo "📊 ARK status:"
ark status
