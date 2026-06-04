# Limitations

The `pod-doctor` agent uses a local LLM (either **Qwen3.5‑9B** by default or **Hermes 3:8B** as a fallback). While these models are capable assistants for many tasks, they have inherent limitations that users should be aware of.

## ✅ What the agent does well

- Listing all pods in a namespace
- Describing a pod (with Qwen, often resolves short names like "coredns" without requiring the full suffix)
- Fetching logs and summarizing warnings
- Showing CPU/memory usage
- Listing events for a specific pod
- Suggesting remediation steps based on observed anomalies

## ❌ What the agent cannot do reliably (both models)

- **Counting occurrences** (e.g., “how many POST requests”) – The models cannot count accurately. Use `kubectl` with `grep` and `wc` instead.
- **Extracting structured data** (JSON, CSV) – The output may be hallucinated or incomplete.
- **Following complex formatting instructions** – The model often ignores strict output format requests.

## 📊 Model‑specific notes

| Limitation / Feature | Hermes 3:8B | Qwen3.5‑9B (default) |
|----------------------|-------------|----------------------|
| **Partial pod name resolution** (e.g., "coredns") | Unreliable – will often ask for full name | Often works, but may occasionally still fail |
| **Speed** | Fast (2‑3 sec/query) | Slower (5‑10 sec/query on CPU) |
| **Tool calling accuracy** | Good | Excellent |
| **Verbosity** | Concise | More detailed answers |

## 💡 Recommendations

- **For maximum reliability**, use Qwen3.5‑9B (the default). If you prefer speed over accuracy, switch to Hermes by editing `agents/pod-doctor/agent.yaml` and changing `modelRef.name` to `hermes-3-8b`.
- For any precise operation (counting, timestamps, exact numbers), **use `kubectl` directly**.
- For the best experience with Qwen:
  - You can usually use short pod names (e.g., "coredns").
  - If the agent still fails, first list pods to get the exact name.
- For Hermes:
  - Always list pods first to obtain the full name before describing or getting logs.
  - Accept that tool calls may occasionally be misinterpreted.
