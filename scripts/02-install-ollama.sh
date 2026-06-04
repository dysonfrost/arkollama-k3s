#!/usr/bin/env bash

set -e

echo "🌀 Creating namespace ollama-system..."
kubectl create namespace ollama-system --dry-run=client -o yaml | kubectl apply -f -

echo "📦 Applying PersistentVolumeClaim..."
kubectl apply -f k8s/ollama/pvc.yaml

echo "🚀 Deploying Ollama (Deployment + Service)..."
kubectl apply -f k8s/ollama/deployment.yaml
kubectl apply -f k8s/ollama/service.yaml

echo "⏳ Waiting for Ollama pod to be ready..."
kubectl -n ollama-system wait --for=condition=ready pod -l app=ollama --timeout=180s

echo "📥 Pulling Hermes 3:8B quantized model (approx 5GB)..."
kubectl -n ollama-system exec deployment/ollama -- ollama pull hermes3:8b-llama3.1-q4_K_M

echo "📥 Pulling Qwen3.5:9B model (approx 5GB)..."
kubectl -n ollama-system exec deployment/ollama -- ollama pull qwen3.5:9b

echo "✅ Ollama is ready. Models available: hermes3:8b-llama3.1-q4_K_M, qwen3.5:9b"

echo ""
echo "🔍 Verifying model list:"
kubectl -n ollama-system exec deployment/ollama -- ollama list
