# Kubernetes Troubleshooting Playbook

This guide contains the professional sequence of commands used to diagnose and resolve container failures in a production-like environment.

## 1. The Diagnostic Trinity
When a pod is failing, always run these three in order:

1. **Check Status:**
   `kubectl get pods`
   *What to look for:* `Restarts` > 0, `Status` != `Running`.

2. **Check Events:**
   `kubectl describe pod <pod-name>`
   *What to look for:* The "Events" section at the bottom (e.g., `OOMKilled`, `FailedScheduling`).

3. **Check Logs:**
   `kubectl logs <pod-name> --previous`
   *What to look for:* Application-level errors or stack traces that occurred right before the crash.

## 2. Advanced Diagnostic Commands
Use these when the basic trinity doesn't give you the answer:

| Command | Purpose |
| :--- | :--- |
| `kubectl get events --sort-by=.metadata.creationTimestamp` | See a chronological timeline of everything happening in the cluster. |
| `kubectl get pod <pod-name> -o yaml` | View the full "Status" object, including specific exit codes and timestamps. |
| `kubectl get pods -o wide` | Identify which Node the pod is running on to rule out hardware/node issues. |
| `kubectl top pod` | Monitor real-time CPU and Memory usage (requires Metrics Server). |

## 3. The "Fix" Cheat Sheet

### OOMKilled (Exit Code 137)
* **Immediate Fix:** Increase `resources.limits.memory` in the deployment YAML.
* **Analysis:** Profile the application for memory leaks or check if the load has increased.

### CrashLoopBackOff (Exit Code 1)
* **Immediate Fix:** Check logs for missing environment variables, secrets, or database connection strings.
* **Infrastructure Fix:** Adjust `livenessProbe` or `readinessProbe` if the app needs more time to start.

### ImagePullBackOff
* **Immediate Fix:** Verify image spelling, tags, and Docker Hub credentials (imagePullSecrets).