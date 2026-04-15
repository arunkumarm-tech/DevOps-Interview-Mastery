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