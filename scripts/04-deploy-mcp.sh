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

echo "Waiting for ARK to discover tools..."
for i in {1..30}; do
  if kubectl get tool kubernetes-mcp-server-pods-list &>/dev/null; then
    echo "Tools are ready."
    break
  fi
  if [ $i -eq 30 ]; then
    echo "Timeout waiting for tools. You may need to wait a few more seconds before deploying agents."
  fi
  sleep 2
done

echo "MCP server ready. Tools should now be available in ARK."
