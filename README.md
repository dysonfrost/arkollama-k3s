# arkollama-k3s

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-blue)](https://kubernetes.io)
[![ARK](https://img.shields.io/badge/ARK-0.1.63-orange)](https://github.com/mckinsey/agents-at-scale-ark)

**Local AI agents powered by McKinsey's ARK framework, k3s, and Ollama (Hermes 3:8B).**

This project demonstrates how to deploy and interact with AI agents inside a local Kubernetes cluster. Each agent has its own permissions (RBAC) and can be used for typical DevOps/SRE tasks – pod diagnosis, log inspection, resource usage monitoring, and more.

---

## 🚀 Features

- **Lightweight local cluster** – uses k3s, no cloud dependencies.
- **Local LLM** – Hermes 3:8B (optimised for CPU/GPU) served by Ollama.
- **Agentic framework** – ARK by McKinsey provides native Kubernetes CRDs for agents, models, queries.
- **MCP integration** – A full Kubernetes MCP server (19 tools) allows agents to interact with the cluster:
  - List pods, describe pods, fetch logs, show events, display CPU/memory usage.
- **Ready‑to‑use agent** – `pod-doctor` diagnoses pods, fetches logs, and suggests fixes.
- **Isolated RBAC** – each agent has its own ServiceAccount and fine‑grained permissions.
- **Non‑destructive** – does not overwrite your existing `~/.kube/config`.
- **Clean commit history** – incremental, well‑documented steps.

---

## 📋 Prerequisites

- Linux (tested on Arch Linux, but any distribution works)
- 4+ CPU cores, 16+ GB RAM (32 GB recommended)
- [k3s](https://k3s.io/)
- [Helm](https://helm.sh/) (v3+)
- [Node.js](https://nodejs.org/) (v18+) and [npm](https://www.npmjs.com/)
- [curl](https://curl.se/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [make](https://www.gnu.org/software/make/)
- [git](https://git-scm.com/)

> 💡 The installation scripts will automatically install k3s, Ollama, ARK, and the MCP server for you.

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

### 4. Install ARK framework and register the LLM model

```bash
make install-ark
# or: ./scripts/03-install-ark.sh
```

The script will ask you to select components. **Uncheck `localhost-gateway` and `noah`** (Noah is experimental).  
All components will be installed in the `default` namespace.  
After ARK is installed, the Hermes 3:8B model is automatically registered.

### 5. Deploy the MCP server (Kubernetes tools)

```bash
make deploy-mcp
```

This deploys:
- Namespace `mcp-system`
- ServiceAccount, ClusterRole, ClusterRoleBinding
- Deployment and Service for the Kubernetes MCP server
- An `MCPServer` resource that ARK uses to discover tools

After successful deployment, ARK automatically discovers 19 tools (e.g., `pods-list`, `pods-get`, `pods-log`, `events-list`, `pods-top`).  
Verify with:

```bash
kubectl get mcpserver kubernetes-mcp-server
kubectl get tools | grep kubernetes-mcp-server
```

### 6. Deploy the `pod-doctor` agent

```bash
make deploy-agents
```

This command:
- Applies RBAC for `pod-doctor` (ServiceAccount, Role, RoleBinding)
- Creates the Agent resource
- Deploys example queries (optional)

---

## 🧪 Usage

### List agents and models

```bash
# Using the ARK CLI
export KUBECONFIG="$HOME/.kube/arkollama-k3s.config"
ark agents
ark models

# Using kubectl
kubectl get agents
kubectl get models
```

### Interact with the `pod-doctor` agent

The agent can list pods, describe a pod (requires the exact full name), fetch logs, show events, and display resource usage.

#### Examples

| Task | Command |
|------|---------|
| List all pods in a namespace | `ark query agent/pod-doctor "List pods in kube-system"` |
| Describe a pod (exact name) | `ark query agent/pod-doctor "Describe pod coredns-8db54c48d-zzk5d in namespace kube-system"` |
| Get logs (summary) | `ark query agent/pod-doctor "Show logs of ollama-688d557dc8-n77dp in namespace ollama-system"` |
| Show events | `ark query agent/pod-doctor "Show recent events for pod coredns-8db54c48d-zzk5d in kube-system"` |
| Resource usage (explicit tool call) | `ark query agent/pod-doctor "Call kubernetes-mcp-server-pods-top with namespace='ollama-system' and podName='ollama-688d557dc8-n77dp'"` |

> ⚠️ **Important**: The agent cannot guess partial pod names (e.g., “coredns”). Always list pods first to get the exact full name.

### Using declarative queries (YAML)

Create a file `query.yaml`:

```yaml
apiVersion: ark.mckinsey.com/v1alpha1
kind: Query
metadata:
  name: list-pods-default
spec:
  input: "List all pods in namespace default"
  targets:
    - name: pod-doctor
      type: agent
```

Apply and check the result:

```bash
kubectl apply -f query.yaml
kubectl get query list-pods-default -w
kubectl get query list-pods-default -o jsonpath='{.status.response.content}'
```

### Direct API access

```bash
kubectl port-forward -n default svc/ark-api 8080:80 &
curl -X POST http://localhost:8080/v1/agents/default/pod-doctor/query \
  -H "Content-Type: application/json" \
  -d '{"input": "List pods in kube-system"}'
```

---

## 📁 Project Structure

```
arkollama-k3s/
├── agents/
│   └── pod-doctor/           # Agent definition, RBAC, and queries
│       ├── agent.yaml
│       ├── rbac.yaml
│       └── queries/          # Example query YAMLs
├── k8s/
│   ├── ollama/               # Ollama PVC, Deployment, Service
│   ├── ark/                  # Model configuration, MCPServer, ARK resources
│   └── mcp/                  # MCP server deployment (ServiceAccount, Deployment, Service)
├── scripts/                  # Installation and cleanup scripts
├── docs/
│   ├── architecture.md
│   ├── troubleshooting.md
│   └── limitations.md
├── Makefile
└── README.md
```

---

## 🗑️ Cleanup

To remove everything (agents, MCP server, ARK, Ollama, PVCs):

```bash
make clean
```

To also remove k3s itself, run:

```bash
sudo /usr/local/bin/k3s-uninstall.sh
```

---

## ⚠️ Limitations

The `pod-doctor` agent uses the **Hermes 3:8B** local LLM. It is:

**✅ Good for:**
- Listing pods
- Describing a pod (with the exact full name)
- Summarising logs and events
- Suggesting remediation steps

**❌ Not reliable for:**
- Guessing partial pod names – it will refuse and ask you to list pods first.
- Counting occurrences (e.g., “how many POST requests”) – use `kubectl` with `grep` and `wc` instead.
- Extracting precise timestamps or structured data (JSON).

For a full list of limitations, see [`docs/limitations.md`](docs/limitations.md).

---

## 🤝 Contributing

Issues and pull requests are welcome.  
For major changes, please open an issue first to discuss what you would like to change.

---

## 📄 License

MIT © [dysonfrost](https://github.com/dysonfrost)

---

## 🙏 Acknowledgements

- [ARK framework](https://github.com/mckinsey/agents-at-scale-ark) by McKinsey
- [Ollama](https://ollama.com) for easy local LLM serving
- [k3s](https://k3s.io) by Rancher
- [Hermes 3:8B](https://ollama.com/library/hermes3:8b-llama3.1-q4_K_M) model
- [Kubernetes MCP Server](https://github.com/containers/kubernetes-mcp-server)
