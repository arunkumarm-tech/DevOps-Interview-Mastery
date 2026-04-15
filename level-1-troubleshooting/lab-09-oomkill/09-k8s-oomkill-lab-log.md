# Lab Log: Troubleshooting Kubernetes OOMKilled Errors

This lab demonstrates how Kubernetes handles containers that exceed their memory limits.

## 1. The Setup (Simulating Memory Pressure)
Created a pod manifest (`oom-test.yaml`) using a stress-testing image:
* **Image:** `polinux/stress`
* **Limits:** `10Mi` (Memory)
* **Action:** Commanded the container to grab `20Mi` of memory.

**Command used to deploy:**
```bash
kubectl apply -f oom-test.yaml


## 3. The Resolution (The Fix)
**Action:** Identified that the application required more memory than the allocated 10Mi limit. Updated the deployment manifest to increase the limits.

**Modified YAML configuration:**
```yaml
    resources:
      limits:
        memory: "30Mi"  # Increased to provide breathing room
      requests:
        memory: "20Mi"