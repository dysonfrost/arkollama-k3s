# arkollama-k3s

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-blue)](https://kubernetes.io)
[![ARK](https://img.shields.io/badge/ARK-0.1.63-orange)](https://github.com/mckinsey/agents-at-scale-ark)

**Local AI agents powered by McKinsey's ARK framework, k3s, and Ollama (Hermes 3:8B).**

This project demonstrates how to deploy and interact with multiple AI agents inside a local Kubernetes cluster. Each agent has its own permissions (RBAC) and can be used for typical DevOps/SRE tasks – pod diagnosis, resource optimisation, security auditing, manifest generation, and Prometheus monitoring.

---

## 🚀 Features

- **Lightweight local cluster** – uses k3s, no cloud dependencies.
- **Local LLM** – Hermes 3:8B (optimised for CPU/GPU) served by Ollama.
- **Agentic framework** – ARK by McKinsey provides native Kubernetes CRDs for agents, models, queries.
- **Production‑grade agents** – five ready‑to‑use examples:
  - `pod-doctor` – diagnose failing pods (logs, events, describe)
  - `resource-sage` – right‑size CPU/memory requests/limits
  - `security-gate` – detect privileged containers and risky settings
  - `manifest-master` – generate Kubernetes YAML from natural language
  - `slo-assistant` – answer Prometheus queries (error rate, latency)
- **Isolated RBAC** – each agent has its own ServiceAccount and fine‑grained permissions.
- **Non‑destructive** – does not overwrite your existing `~/.kube/config`.
- **Clean commit history** – incremental, well‑documented steps.

### `pod-doctor` – Planned MCP Tools

The `pod-doctor` agent will eventually use the following Model Context Protocol (MCP) tools to interact with the cluster:

- `kubectl-describe-pod` – retrieves pod details (status, events, conditions)
- `kubectl-logs` – fetches the last 50 lines of logs from a container
- `kubectl-events` – lists recent events for a specific pod

These tools are not yet implemented in this version. Currently, the agent can still answer general pod diagnosis questions based on its training data.

## 📋 Prerequisites

- Linux (tested on Archlinux, but any distribution works)
- 4+ CPU cores, 16+ GB RAM (32 GB recommended)
- [k3s](https://k3s.io/)
- [Helm](https://helm.sh/) (v3+)
- [Node.js](https://nodejs.org/) (v18+) and [npm](https://www.npmjs.com/)
- [curl](https://curl.se/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [make](https://www.gnu.org/software/make/)
- [git](https://git-scm.com/)

> 💡 The installation scripts will automatically install k3s, Ollama, and ARK for you.
---

## 🏗️ Architecture

See [`docs/architecture.md`](./docs/architecture.md) for the detailed architecture diagram and component descriptions.

---

## 🔧 Installation

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/arkollama-k3s.git
cd arkollama-k3s
```

### 2. Install k3s

```bash
make install-k3s
# or directly: ./scripts/01-install-k3s.sh
```

Your k3s kubeconfig will be saved as `~/.kube/arkollama-k3s.config`.  
The script never overwrites your existing `~/.kube/config`.

### 3. Deploy Ollama and pull the Hermes 3:8B model

```bash
make install-ollama
# or: ./scripts/02-install-ollama.sh
```

This creates a PVC, Deployment, and Service. It then downloads the 4.9 GB model (`hermes3:8b-llama3.1-q4_K_M`).  
**This may take 5‑10 minutes** depending on your internet connection.

### 4. Install ARK framework

```bash
make install-ark
# or: ./scripts/03-install-ark.sh
```

The script will ask you to select components. **Uncheck `localhost-gateway` and `noah`** (Noah is experimental).  
All components will be installed in the `default` namespace.
After ARK is installed, the Hermes 3:8B model is automatically registered.

> 💡 **ARK version**: This project was tested with ARK `0.1.63`.  
> For newer versions, check the [official ARK releases](https://github.com/mckinsey/agents-at-scale-ark/releases) and adjust the installation scripts if necessary.

### 5. Deploy all agents

```bash
make deploy-agents
# or: ./scripts/manage-agents.sh apply
```

This will:
- Apply RBAC for each agent (ServiceAccount, Role, RoleBinding)
- Create the Agent resources
- Deploy example queries (optional)

---

## 🧪 Usage

### List agents and models

```bash
# Using the ARK CLI (requires correct KUBECONFIG)
export KUBECONFIG=~/.kube/arkollama-k3s.config
ark agents
ark models

# Or using kubectl
kubectl get agents
kubectl get models
```

### Send a query to an agent (declarative – YAML)

```bash
kubectl apply -f agents/pod-doctor/queries/diagnose-coredns.yaml
kubectl get queries -w
```

### Send a query via the ARK API (interactive)

```bash
# Port‑forward the ARK API
kubectl port-forward -n default svc/ark-api 8080:80 &
curl -X POST http://localhost:8080/v1/agents/default/pod-doctor/query \
  -H "Content-Type: application/json" \
  -d '{"input": "Why is the coredns pod in kube-system not ready?"}'
```

### Run a quick test with the ARK CLI

```bash
ark query agent/pod-doctor "List all pods in namespace kube-system"
```

---

## 🗑️ Cleanup

To remove everything (agents, ARK, Ollama, PVCs):

```bash
make clean
```

To also remove k3s itself, run:

```bash
sudo /usr/local/bin/k3s-uninstall.sh
```

---

## 📁 Project Structure

```
arkollama-k3s/
├── agents/                     # Each agent is self‑contained
│   ├── pod-doctor/
│   │   ├── agent.yaml
│   │   ├── rbac.yaml
│   │   └── queries/
│   ├── resource-sage/
│   ├── security-gate/
│   ├── manifest-master/
│   └── slo-assistant/
├── k8s/
│   ├── ollama/                 # Ollama deployment (PVC, Deployment, Service)
│   └── ark/                    # Shared model configuration
├── scripts/
│   ├── 01-install-k3s.sh
│   ├── 02-install-ollama.sh
│   ├── 03-install-ark.sh
│   ├── 04-manage-agents.sh
│   └── 05-cleanup.sh
├── docs/
│   ├── architecture.md
│   └── troubleshooting.md
├── Makefile
└── README.md
```

---

## 🤝 Contributing

Issues and pull requests are welcome.  
For major changes, please open an issue first to discuss what you would like to change.

---

## 📄 License

MIT © Jérémy Reisser

---

## 🙏 Acknowledgements

- [ARK framework](https://github.com/mckinsey/agents-at-scale-ark) by McKinsey
- [Ollama](https://ollama.com) for easy local LLM serving
- [k3s](https://k3s.io) by Rancher
- [Hermes 3:8B](https://ollama.com/library/hermes3:8b-llama3.1-q4_K_M) model
