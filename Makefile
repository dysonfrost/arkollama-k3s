.PHONY: help install-k3s install-ollama install-ark deploy-mcp deploy-ark-resources deploy-agents clean

help:
	@echo "Available targets:"
	@echo "  install-k3s          - Install k3s cluster"
	@echo "  install-ollama       - Deploy Ollama and pull Hermes model"
	@echo "  install-ark          - Install ARK framework and register the model"
	@echo "  deploy-mcp           - Deploy Kubernetes MCP server (tools for pod-doctor)"
	@echo "  deploy-ark-resources - Register model and MCPServer (depends on deploy-mcp)"
	@echo "  deploy-agents        - Deploy all agents (depends on deploy-ark-resources)"
	@echo "  clean                - Remove everything (agents, ARK, Ollama, MCP, PVCs)"

install-k3s:
	./scripts/01-install-k3s.sh

install-ollama:
	./scripts/02-install-ollama.sh

install-ark:
	./scripts/03-install-ark.sh

deploy-mcp:
	./scripts/04-deploy-mcp.sh

deploy-ark-resources: deploy-mcp
	kubectl apply -f k8s/ark/model-config.yaml

deploy-agents: deploy-ark-resources
	./scripts/manage-agents.sh apply

clean:
	./scripts/05-cleanup.sh
