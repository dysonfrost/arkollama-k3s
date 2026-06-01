# Troubleshooting

Common issues and solutions when deploying `arkollama-k3s`.

---

## 🔧 K3s installation

### `kubectl` cannot connect to the cluster (TLS certificate error)

**Symptom**:
```
Error: kubernetes cluster unreachable: Get "https://127.0.0.1:6443/version": tls: failed to verify certificate: x509: certificate signed by unknown authority
```

**Cause**: k3s uses a self‑signed certificate. The `KUBECONFIG` variable is not set, so `kubectl` uses the wrong configuration (e.g., a production config from `~/.kube/config`).

**Solution**:
```bash
export KUBECONFIG="$HOME/.kube/arkollama-k3s.config"
```
The installation scripts (`03-install-ark.sh` and `04-cleanup.sh`) automatically set this variable. If running manual commands, set it first.

---

## 🐳 Ollama deployment

### Model pull fails with `file does not exist`

**Symptom**:
```
Error: pull model manifest: file does not exist
```

**Cause**: The model name is incorrect or not available on Ollama's registry.

**Solution**: Use the correct model identifier. This project uses:
```
hermes3:8b-llama3.1-q4_K_M
```
Verify available models with:
```bash
kubectl -n ollama-system exec deployment/ollama -- ollama list
```

### Ollama pod crashes with `CrashLoopBackOff`

**Symptom**: The Ollama pod restarts repeatedly.

**Cause**: The persistent volume is read‑only or has permission issues.

**Solution**:
1. Delete the PVC: `kubectl delete pvc -n ollama-system ollama-storage`
2. Re‑run `make install-ollama` – a new PVC will be created.

---

## 📦 ARK installation

### Cert‑manager images fail to pull (`ImagePullBackOff`)

**Symptom**:
```
Failed to pull image "quay.io/jetstack/cert-manager-controller:v1.20.2": ... 504 Gateway Time-out
```

**Cause**: The `quay.io` registry is sometimes slow or returns transient errors (502/504).

**Solution**:
Wait a few minutes and retry `ark install`. If the problem persists, pre‑pull the images manually on your node:

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

### ARK components are installed but `ark agents` / `ark models` show nothing

**Symptom**:
```
ark! warning: no agents available
No models found
```

**Cause**: The CLI uses the namespace from your current `kubectl` context, but resources are in a different namespace.

**Solution**:
- Make sure you are using the correct kubeconfig (see TLS error above).
- Set the default namespace for your context:
  ```bash
  kubectl config set-context --current --namespace=default
  ```
- This project places all ARK resources in the `default` namespace for simplicity.

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

## 🤖 Agents

### Agent fails with `ImagePullBackOff` or `CrashLoopBackOff`

**Symptom**: The agent pod created by ARK cannot start.

**Cause**: The agent image is missing or the agent definition references an unavailable model.

**Solution**:
1. Verify that the model is registered and `ModelAvailable` condition is `True`:
   ```bash
   kubectl get model hermes-3-8b -o yaml | grep -A5 Status
   ```
2. Check the agent logs:
   ```bash
   kubectl logs -l ark.agent=pod-doctor -n default
   ```
3. Ensure the agent’s `modelRef` matches the model name and namespace.

## 🧹 Cleanup

### `make clean` fails with TLS errors

**Symptom**:
```
Error: kubernetes cluster unreachable: ... x509: certificate signed by unknown authority
```

**Cause**: The cleanup script does not have the correct `KUBECONFIG` set.

**Solution**: The script `04-cleanup.sh` now sets `KUBECONFIG` automatically. If you still see errors, run:
```bash
export KUBECONFIG="$HOME/.kube/arkollama-k3s.config"
make clean
```

## 📝 Getting help

If you encounter an issue not listed here, please open a GitHub issue with:
- The exact command you ran
- The full error output
- Your environment (OS, k3s version, ARK version)
