# Architecture

```mermaid
flowchart TD
    A[User / Developer] -->|kubectl / ark CLI| B[k3s Cluster]

    subgraph B [k3s Local Cluster]
        direction TB
        C[Ollama Namespace]
        D[ARK Namespace]
        E[MCP Server Namespace]
    end

    subgraph C [Namespace: ollama-system]
        C1[Ollama Pod<br>Hermes 3:8B + Qwen3.5‑9B]
        C2[Service<br>ollama-service:11434]
    end

    subgraph D [Namespace: default]
        D1[ARK Controller]
        D2[Agent Pod<br>pod-doctor]
        D3[Model CRDs<br>hermes-3-8b, qwen3.5-9b]
        D4["Tools (auto‑created)"]
    end

    subgraph E [Namespace: mcp-system]
        E1[Kubernetes MCP Server Pod]
        E2[Service<br>kubernetes-mcp-server:8080]
    end

    D3 -->|references| D1
    D1 -->|creates & manages| D2
    D2 -->|LLM request| C2
    C2 -->|routes to| C1
    D2 <-->|tool calls via MCP| E2
    E2 -->|executes kubectl| E1
```

## Components

- **k3s** – lightweight Kubernetes cluster, runs on local machine (Traefik disabled).
- **Ollama** – serves two LLMs (Hermes 3:8B and Qwen3.5‑9B) via a single Deployment, PersistentVolumeClaim, and Service. Both models are pulled by default. Ollama exposes an OpenAI‑compatible API at `/v1`.
- **ARK** – agentic runtime by McKinsey, provides CRDs for agents, models, queries, and MCP servers. Installed in the `default` namespace.
- **Kubernetes MCP Server** – dedicated server in the `mcp-system` namespace. Exposes 19 Kubernetes tools (pods-list, pods-get, pods-log, events-list, pods-top, etc.). Registered as an `MCPServer` resource in ARK, which automatically creates corresponding `Tool` CRDs in the `default` namespace.
- **`pod-doctor` agent** – uses the `qwen3.5-9b` model by default (more accurate for tool calling). It calls the MCP tools to inspect the cluster (describe pods, get logs, show events, etc.). Its RBAC is minimal because all permissions are delegated to the MCP server.

All ARK resources (agents, models, tools) are in the `default` namespace for simplicity. The MCP server runs in `mcp-system` for isolation. This architecture allows agents to interact with the cluster without needing `kubectl` inside their container.
