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
ark install

# Register the LLM model in ARK
echo "📝 Registering Hermes 3:8B model in ARK..."
if [ -f "k8s/ark/model-config.yaml" ]; then
    kubectl apply -f k8s/ark/model-config.yaml
else
    echo "⚠️ model-config.yaml not found - skipping model registration."
fi

echo "📊 ARK status:"
ark status
