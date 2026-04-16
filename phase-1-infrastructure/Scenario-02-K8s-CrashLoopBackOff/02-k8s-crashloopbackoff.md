# Scenario 2: Kubernetes CrashLoopBackOff

### The Problem
A critical microservice is stuck in `CrashLoopBackOff` after a new deployment. This means the pod starts, crashes, and Kubernetes tries to restart it repeatedly.

### The Troubleshooting Steps (The "4-Command" Rule)
1. **`kubectl logs <pod-name> --previous`**: See why the last instance crashed (look for application errors or "Exit Code 1").
2. **`kubectl describe pod <pod-name>`**: Check the "Events" section. Look for `OOMKill` (Memory issue) or `Liveness probe failed`.
3. **`kubectl get pod <pod-name> -o yaml`**: Check if environment variables or secrets are missing.
4. **`kubectl get events --sort-by=.metadata.creationTimestamp`**: See a timeline of what happened in the cluster.

### The Resolution
* **OOMKill:** Increase memory limits in the deployment manifest.
* **Exit Code 1:** Fix the application code or missing configuration file.
* **Probe Failure:** Adjust the `initialDelaySeconds` for the liveness probe.