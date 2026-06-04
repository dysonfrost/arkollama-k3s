# arkollama-k3s

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-blue)](https://kubernetes.io)
[![ARK](https://img.shields.io/badge/ARK-0.1.63-orange)](https://github.com/mckinsey/agents-at-scale-ark)

## ⚡ Quickstart

Get a working AI agent on your local Kubernetes cluster with one command.

### Prerequisites

- [Helm](https://helm.sh/), [Node.js](https://nodejs.org/) (v18+), [kubectl](https://kubernetes.io/docs/tasks/tools/), [make](https://www.gnu.org/software/make/), [git](https://git-scm.com/)

### One‑command installation

```bash
git clone https://github.com/dysonfrost/arkollama-k3s.git
cd arkollama-k3s
make install
```

> ⚠️ During `make install`, the ARK installer will ask you to select components. **Uncheck `localhost-gateway` and `noah`** (Noah is experimental), then press Enter.

### Test

```bash
export KUBECONFIG="$HOME/.kube/arkollama-k3s.config"
ark query agent/pod-doctor "List pods in default namespace"
```

All resources are removed with `make clean`. For detailed step‑by‑step instructions, see the [Installation](#-installation) section.

---

## 🚀 Features

- **Lightweight local cluster** – uses k3s, no cloud dependencies.
- **Two local LLMs** – **Hermes 3:8B** (fast, good for simple queries) and **Qwen3.5‑9B** (more accurate for tool calling, used by default).
- **Agentic framework** – ARK by McKinsey provides native Kubernetes CRDs for agents, models, queries, and MCP servers.
- **Full MCP integration** – A dedicated Kubernetes MCP server exposes 19 tools (list pods, describe, logs, events, top, etc.) that agents can call directly.
- **Ready‑to‑use agent** – `pod-doctor` diagnoses pods, fetches logs, shows events, and suggests fixes using Qwen3.5‑9B.
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

### 3. Deploy Ollama and pull both models (Hermes + Qwen)

```bash
make install-ollama
# or: ./scripts/02-install-ollama.sh
```

This creates a PVC, Deployment, and Service. It then downloads:
- **Hermes 3:8B** (`hermes3:8b-llama3.1-q4_K_M`, ~4.9 GB)
- **Qwen3.5‑9B** (`qwen3.5:9b`, ~5 GB)

**This may take 10‑15 minutes** depending on your internet connection.

### 4. Install ARK framework and register both models

```bash
make install-ark
# or: ./scripts/03-install-ark.sh
```

The script will ask you to select components. **Uncheck `localhost-gateway` and `noah`** (Noah is experimental).  
All components will be installed in the `default` namespace.  
After ARK is installed, **both models** are automatically registered:
- `hermes-3-8b` (fast)
- `qwen3.5-9b` (more accurate, default for the agent)

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

### 6. Deploy the `pod-doctor` agent (uses Qwen by default)

```bash
make deploy-agents
```

This command:
- Applies RBAC for `pod-doctor` (ServiceAccount, Role, RoleBinding)
- Creates the Agent resource (referencing `qwen3.5-9b` and the MCP tools)
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

The agent can list pods, describe a pod, fetch logs, show events, and display resource usage. With Qwen3.5‑9B, the agent can often find the full pod name even if you give a short prefix (e.g., "coredns"), but providing the exact name is still recommended for reliability.

#### Examples

| Task | Command |
|------|---------|
| List all pods in a namespace | `ark query agent/pod-doctor "List pods in kube-system"` |
| Describe a pod (short name works) | `ark query agent/pod-doctor "Describe coredns pod in kube-system"` |
| Get logs | `ark query agent/pod-doctor "Show logs of ollama pod in ollama-system"` |
| Show events | `ark query agent/pod-doctor "Show events for coredns in kube-system"` |
| Resource usage | `ark query agent/pod-doctor "Top pods in default namespace"` |

> 💡 **Tip**: If the agent fails to resolve a short name, list pods first to get the exact name, then run the describe/log command.

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
│   ├── ark/                  # Model configurations (Hermes + Qwen)
│   └── mcp/                  # MCP server deployment (ServiceAccount, Deployment, Service, MCPServer)
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

## 📊 Model Comparison

| Feature | Hermes 3:8B | Qwen3.5‑9B |
|---------|-------------|-------------|
| **Size (quantized)** | ~4.9 GB | ~5 GB |
| **Memory usage** | ~5‑6 GB | ~6‑7 GB |
| **Inference speed (CPU)** | 2‑3 sec/query | 5‑10 sec/query |
| **Tool calling accuracy** | Good | Excellent |
| **Short pod name resolution** | Unreliable | Often works |
| **Log summarisation** | Good | Very good |
| **Reasoning depth** | Basic | Deeper |
| **Context window** | 32 k tokens | 262 k tokens |
| **Best for** | Speed, simple queries | Accuracy, complex tool‑calling |
| **Default agent model** | No (fallback) | Yes (pod-doctor) |

Both models are pulled by default. To switch the agent to Hermes, edit `agents/pod-doctor/agent.yaml` and change `modelRef.name` to `hermes-3-8b`.

---

## ⚠️ Limitations

The `pod-doctor` agent uses the **Qwen3.5‑9B** local LLM by default. Qwen is **more accurate** for tool calling but **slower** (5‑10 seconds per query on CPU). Hermes is faster (~2‑3 seconds) but may make more mistakes.

**✅ Good for:**
- Listing pods
- Describing a pod (with the exact full name)
- Summarising logs and events
- Suggesting remediation steps

**❌ Not reliable for:**
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
- [Qwen3.5‑9B](https://ollama.com/library/qwen3.5) model
- [Kubernetes MCP Server](https://github.com/containers/kubernetes-mcp-server)
