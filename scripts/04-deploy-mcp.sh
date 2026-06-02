#!/usr/bin/env bash

set -e

echo "Deploying Kubernetes MCP server..."

kubectl apply -f k8s/mcp/namespace.yaml
kubectl apply -f k8s/mcp/rbac.yaml
kubectl apply -f k8s/mcp/deployment.yaml
kubectl apply -f k8s/mcp/service.yaml
kubectl apply -f k8s/ark/mcpserver.yaml

echo "Waiting for MCP server pod to be ready..."
kubectl wait --for=condition=ready pod -l app=kubernetes-mcp-server -n mcp-system --timeout=60s

echo "Waiting additional 5 seconds for ARK to discover tools..."
sleep 5

echo "MCP server ready. Tools should now be available in ARK."
