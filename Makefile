.PHONY: help install-k3s install-ollama install-ark deploy-mcp deploy-agents clean

help:
	@echo "Available targets:"
	@echo "  install-k3s    - Install k3s cluster"
	@echo "  install-ollama - Deploy Ollama and pull Hermes model"
	@echo "  install-ark    - Install ARK framework and register the model"
	@echo "  deploy-mcp     - Deploy Kubernetes MCP server (tools for agents)"
	@echo "  deploy-agents  - Deploy all agents (RBAC + agent definitions + queries)"
	@echo "  clean          - Remove everything (agents, ARK, Ollama, MCP, PVCs)"

install-k3s:
	./scripts/01-install-k3s.sh

install-ollama:
	./scripts/02-install-ollama.sh

install-ark:
	./scripts/03-install-ark.sh

deploy-mcp:
	./scripts/04-deploy-mcp.sh

deploy-agents:
	./scripts/manage-agents.sh apply

clean:
	./scripts/05-cleanup.sh
