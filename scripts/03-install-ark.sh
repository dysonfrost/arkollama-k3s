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

# Register both LLM models in ARK
echo "📝 Registering Hermes 3:8B model..."
if [ -f "k8s/ark/model-config-hermes.yaml" ]; then
    kubectl apply -f k8s/ark/model-config-hermes.yaml
else
    echo "⚠️ model-config-hermes.yaml not found - skipping Hermes model registration."
fi

echo "📝 Registering Qwen3.5:9B model..."
if [ -f "k8s/ark/model-config-qwen.yaml" ]; then
    kubectl apply -f k8s/ark/model-config-qwen.yaml
else
    echo "⚠️ model-config-qwen.yaml not found - skipping Qwen model registration."
fi

echo "📊 ARK status:"
ark status
