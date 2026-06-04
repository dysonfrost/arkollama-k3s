# Troubleshooting

Common issues and solutions when deploying and using `arkollama-k3s`.

---

## 🤖 Agent `pod-doctor` issues

### Agent cannot resolve a short pod name

**Symptom**: You ask `"Describe coredns pod in kube-system"` but the agent says it cannot find the pod or asks for the full name.

**Cause**: The model may not always resolve the full name from a short prefix, especially with Hermes. Qwen3.5‑9B (the default) is more reliable but not perfect.

**Solution**:
- Use the full pod name (obtained from listing pods first):
  ```bash
  ark query agent/pod-doctor "List pods in kube-system"
  ark query agent/pod-doctor "Describe pod coredns-8db54c48d-zzk5d in namespace kube-system"
  ```
- If you prefer short names, stick with Qwen (default). You can also rephrase: `"Describe the coredns pod in kube-system"`.

### Agent gives wrong information or ignores tools

**Cause**: The local LLM (especially Hermes) may misinterpret the request or hallucinate.

**Solution**:
- Use Qwen3.5‑9B (the default) – it is more accurate for tool calling.
- If you are using Hermes, switch to Qwen by editing the agent:
  ```bash
  kubectl edit agent pod-doctor
  # Change modelRef.name from "hermes-3-8b" to "qwen3.5-9b"
  ```
- Rephrase your query using explicit tool call syntax:
  ```bash
  ark query agent/pod-doctor "Call kubernetes-mcp-server-pods-get with name='coredns-8db54c48d-zzk5d', namespace='kube-system'"
  ```

### Agent cannot count occurrences or give exact numbers

**Cause**: Local LLMs are not reliable for counting or exact numerical extraction. This is a known limitation.

**Solution**: Use `kubectl` directly for counting:
```bash
kubectl logs -n ollama-system ollama-688d557dc8-n77dp | grep "POST" | wc -l
```

---

## 🐳 Ollama deployment issues

### Model pull fails with `file does not exist`

**Symptom**:
```
Error: pull model manifest: file does not exist
```

**Cause**: The model name is incorrect or not available on Ollama's registry.

**Solution**: Use the correct model identifiers. This project pulls two models by default:
- `hermes3:8b-llama3.1-q4_K_M`
- `qwen3.5:9b`

Verify available models with:
```bash
kubectl -n ollama-system exec deployment/ollama -- ollama list
```

### Ollama pod crashes with `CrashLoopBackOff`

**Symptom**: The Ollama pod restarts repeatedly.

**Cause**: The persistent volume may be corrupted or have permission issues.

**Solution**:
1. Delete the PVC: `kubectl delete pvc -n ollama-system ollama-storage`
2. Re‑run `make install-ollama` – a new PVC will be created and models will be re‑downloaded.

---

## 🤖 MCP server issues

### Tools from `kubernetes-mcp-server` do not appear

**Symptom**: After `make deploy-mcp`, `kubectl get tools | grep kubernetes-mcp-server` shows nothing.

**Cause**: The MCPServer may not have been reconciled yet, or the MCP server pod is not ready.

**Solution**:
1. Wait 10‑15 seconds.
2. Check the MCPServer status:
   ```bash
   kubectl get mcpserver kubernetes-mcp-server -o yaml
   ```
3. Verify the MCP server pod is running:
   ```bash
   kubectl get pods -n mcp-system
   ```
4. If the pod is stuck, check its logs:
   ```bash
   kubectl logs -n mcp-system -l app=kubernetes-mcp-server
   ```

### MCP server pod fails with `ImagePullBackOff`

**Symptom**: The MCP server pod stays in `ImagePullBackOff`.

**Cause**: The container image `ghcr.io/containers/kubernetes-mcp-server:latest` may be temporarily unavailable.

**Solution**:
1. Delete the failing pod:
   ```bash
   kubectl delete pod -n mcp-system -l app=kubernetes-mcp-server
   ```
2. Wait for automatic recreation.
3. If the problem persists, pre‑pull the image manually on your node:
   ```bash
   sudo ctr image pull ghcr.io/containers/kubernetes-mcp-server:latest
   ```

---

## 📦 ARK installation issues

### Cert‑manager images fail to pull (`ImagePullBackOff`)

**Symptom**:
```
Failed to pull image "quay.io/jetstack/cert-manager-controller:v1.20.2": ... 504 Gateway Time-out
```

**Cause**: The `quay.io` registry is sometimes slow or returns transient errors (502/504).

**Solution**:
Wait a few minutes and retry `ark install`. If the problem persists, pre‑pull the images manually on your node (k3s uses containerd):

```bash
sudo ctr image pull quay.io/jetstack/cert-manager-controller:v1.20.2
sudo ctr image pull quay.io/jetstack/cert-manager-cainjector:v1.20.2
sudo ctr image pull quay.io/jetstack/cert-manager-webhook:v1.20.2
sudo ctr image pull quay.io/jetstack/cert-manager-startupapicheck:v1.20.2
```

Then delete the failing pods:
```bash
kubectl delete pods -n cert-manager --all
```

### `ark install` fails with `no endpoints available for service cert-manager-webhook`

**Symptom**:
```
failed to call webhook: Post "https://cert-manager-webhook.cert-manager.svc:443/validate?timeout=30s": no endpoints available for service "cert-manager-webhook"
```

**Cause**: cert‑manager was installed but its webhook pod is not yet ready.

**Solution**:
Wait for the webhook pod to become ready:
```bash
kubectl -n cert-manager wait --for=condition=ready pod -l app=webhook --timeout=120s
```
Then re‑run `ark install`. It will skip already installed components.

---

## 🧹 Cleanup issues

### `make clean` fails with TLS errors

**Symptom**:
```
Error: kubernetes cluster unreachable: ... x509: certificate signed by unknown authority
```

**Cause**: The cleanup script does not have the correct `KUBECONFIG` set.

**Solution**: The script `04-cleanup.sh` (or `05-cleanup.sh` in your project) automatically sets `KUBECONFIG` to `~/.kube/arkollama-k3s.config`. If you still see errors, manually export it:

```bash
export KUBECONFIG="$HOME/.kube/arkollama-k3s.config"
make clean
```

---

## 🐢 Performance considerations

### Qwen3.5‑9B is slow on my machine

**Cause**: Qwen is a larger model (~5 GB) and runs slower on CPU‑only setups (5‑10 seconds per query). Hermes is faster (~2‑3 seconds) but less accurate for tool calling.

**Workaround**:
- Switch the agent to use Hermes for faster responses:
  ```bash
  kubectl edit agent pod-doctor
  # Change modelRef.name to "hermes-3-8b"
  ```
- Alternatively, enable GPU acceleration for Ollama if you have a compatible GPU (see GPU documentation).

---

## 📝 Getting help

If you encounter an issue not listed here, please open a GitHub issue with:
- The exact command you ran
- The full error output
- Your environment (OS, k3s version, ARK version, model used)
