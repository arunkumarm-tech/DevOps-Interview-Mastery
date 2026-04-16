# Lab Log: Troubleshooting Kubernetes Failures

This log tracks the hands-on troubleshooting performed on a local Docker Desktop Kubernetes cluster.

## 1. Simulated Scenario: CrashLoopBackOff
[cite_start]**Problem:** A pod for `faulty-app` was stuck restarting repeatedly. [cite: 11]

**Step-by-Step Troubleshooting:**
1. [cite_start]**Identify the State:** Used `kubectl get pods` to confirm the `CrashLoopBackOff` status. [cite: 11]
2. [cite_start]**Examine Logs:** Ran `kubectl logs <pod-name> --previous` to see why the container failed. [cite: 14]
   * *Observation:* Saw the application started but exited with "Exit Code 1".
3. [cite_start]**Inspect Events:** Ran `kubectl describe pod <pod-name>` to look for resource or probe issues. [cite: 15]
   * *Observation:* Found "Back-off restarting failed container" in the events.

**The Fix:**
Modified the deployment manifest (`broken-dep.yaml`) to change the container command from an immediate exit (`exit 1`) to a long-running process (`sleep 3600`).

## 2. Encountered Scenario: ImagePullBackOff
[cite_start]**Problem:** During the update, the pod status changed to `ImagePullBackOff`. [cite: 15]

**Investigation:**
[cite_start]Ran `kubectl describe pod <pod-name>` and checked the **Events** section. [cite: 15]
* *Observation:* Kubernetes could not pull the `busybox` image due to a temporary network glitch or name resolution issue.

**The Fix:**
Verified the image name in the YAML was `busybox` and re-applied the manifest using `kubectl apply -f broken-dep.yaml`.

## Final Result
Pod status changed to **Running** with `1/1 READY`.