# Scenario 9: Kubernetes Resource Limits (OOMKill)

### The Problem
A pod restarts frequently. Running `kubectl describe pod` shows `Reason: OOMKilled`.

### The Troubleshooting Steps
1. **Identify the Error:** Run `kubectl get pod` and look for a high restart count.
2. **Confirm OOMKill:** Run `kubectl describe pod <pod-name>` and look for `Terminated` with `Reason: OOMKilled` in the container status.
3. **Check Limits:** Look at the `Resources` section in the same output to see the memory `limit`.

### The Resolution
* **Short-term:** Increase the `memory` limit in the deployment YAML.
* **Long-term:** Profile the application to see if there is a memory leak or if the application naturally needs more RAM to handle the load.

### Summary of Fixes for Kubernetes Crashes

| Error | Primary Fix | Command to Verify |
| :--- | :--- | :--- |
| **OOMKilled** | Increase `limits.memory` in YAML | `kubectl top pod` |
| **CrashLoop** | Check App Logs / Fix Entrypoint | `kubectl logs -p` |
| **ImagePull** | Fix Registry Path / Credentials | `kubectl describe pod` |
| **Exit Code 137** | Resource Adjustment (OOM) | `kubectl get pod -o yaml` |