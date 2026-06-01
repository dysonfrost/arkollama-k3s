.PHONY: help install-k3s install-ollama install-ark deploy-agents clean

help:
	@echo "Available targets:"
	@echo "  install-k3s      - Install k3s cluster"
	@echo "  install-ollama   - Deploy Ollama and pull Hermes model"
	@echo "  install-ark      - Install ARK framework and register the model"
	@echo "  deploy-agents    - Deploy all agents (RBAC + agents + queries)"
	@echo "  clean            - Remove everything (agents, ARK, Ollama, PVCs)"

install-k3s:
	./scripts/01-install-k3s.sh

install-ollama:
	./scripts/02-install-ollama.sh

install-ark:
	./scripts/03-install-ark.sh

deploy-agents:
	./scripts/04-manage-agents.sh apply

clean:
	./scripts/05-cleanup.sh
