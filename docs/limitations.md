# Limitations

The `pod-doctor` agent uses the **Hermes 3:8B** model running locally via Ollama. While it is a capable assistant for many tasks, it has inherent limitations that users should be aware of.

## ✅ What the agent does well

- Listing all pods in a namespace
- Describing a pod **when the exact full name** (including the random suffix) is provided
- Fetching logs and summarizing warnings
- Showing CPU/memory usage with the exact pod name
- Listing events for a specific pod
- Suggesting remediation steps based on observed anomalies

## ❌ What the agent cannot do reliably

- **Guessing partial pod names** – The agent will refuse to guess; you must first list the pods to obtain the full name.
- **Counting occurrences** (e.g., “how many POST requests”) – The model cannot count accurately. Use `kubectl` with `grep` and `wc` instead.
- **Extracting structured data** (JSON, CSV) – The output may be hallucinated or incomplete.
- **Following complex formatting instructions** – The model often ignores strict output format requests.

## 💡 Recommendations

- For any precise operation (counting, timestamps, exact numbers), **use `kubectl` directly**.
- To use the agent effectively, always:
  - List pods first to get full names.
  - Use the exact name in subsequent queries.
  - Avoid asking for counts or structured data.
