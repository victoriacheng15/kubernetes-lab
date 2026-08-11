# Day 30: Final Capstone Troubleshooting and Operations Lab

This final capstone project brings together multiple administration, networking, security, and application health concepts. You are tasked with recovering an application that fails to authorize with the API server, loops in container restarts due to a health probe mismatch, and is unreachable externally due to ingress routing issues.

## Project Architecture

```mermaid
graph TD
    User["External Client"] ──►|"HTTP requests"| Ingress["ingress/capstone-ingress"]
    Ingress ──►|"Forwards to Port: 80"| Service["service/capstone-web-svc (Port: 80)"]
    Service ──►|"TargetPort: 80"| Pod["pod/capstone-web"]
    Pod ──►|"Uses token to query Pod API"| APIServer["kube-apiserver"]
```

---

## Troubleshooting Guide

The initial configuration deployed in the `broken/` directory contains three distinct cluster integration bugs:

### Error 1: RBAC Namespace Misalignment

* **Symptom:** The container log output displays: `API Probe check: Pods HTTP Status 403`
* **Root Cause:** The `frontend-sa` ServiceAccount is defined in the `capstone-lab` namespace. However, the RoleBinding `read-pods-binding` specifies the subject's namespace as `default`. Because Kubernetes cannot match the ServiceAccount namespace, the Pod runs without the necessary permissions to list pods.
* **Resolution:** Modify the subject's namespace inside [02-rbac.yaml](manifests/broken/02-rbac.yaml) from `default` to `capstone-lab`.

### Error 2: Liveness Probe Port Mismatch

* **Symptom:** The pod status constantly switches to `CrashLoopBackOff` or reports restarts.
* **Root Cause:** The application container listens on port `80`. The `livenessProbe` configuration in the deployment is configured to test a TCP socket on port `8080`. Since nothing is listening on `8080`, the probe fails repeatedly, prompting the kubelet to kill and restart the container.
* **Resolution:** Update the `livenessProbe.tcpSocket.port` inside [03-frontend.yaml](manifests/broken/03-frontend.yaml) to `80`.

### Error 3: Ingress TargetPort Mismatch

* **Symptom:** External curl requests to the Ingress resource return `503 Service Unavailable` or connection refused.
* **Root Cause:** The Ingress controller receives external traffic and attempts to forward it to the `capstone-web-svc` Service on port `8080`. However, the Service is configured to listen on port `80`.
* **Resolution:** Edit the backend service port number in [05-ingress.yaml](manifests/broken/05-ingress.yaml) to `80`.

---

## Manifest Differences

<details>
<summary>Click to view manifest differences</summary>

Below is a comparison of the key changes between the broken and fixed files:

### RBAC Configuration (02-rbac.yaml)

```diff
 subjects:
   - kind: ServiceAccount
     name: frontend-sa
-    namespace: default
+    namespace: capstone-lab
```

### Frontend Deployment (03-frontend.yaml)

```diff
           livenessProbe:
             tcpSocket:
-              port: 8080
+              port: 80
```

### Ingress Routing (05-ingress.yaml)

```diff
             backend:
               service:
                 name: capstone-web-svc
                 port:
-                  number: 8080
+                  number: 80
```

</details>

---

## Lab Steps

1. **Deploy the Broken State:**

   Deploy the initial set of manifests containing the configuration bugs:

   ```bash
   kubectl apply -f phase-4/day-30/manifests/broken/01-namespace.yaml
   kubectl apply -f phase-4/day-30/manifests/broken/
   ```

2. **Diagnose Pod Restarts and API Failures:**

   List the pods in the namespace to observe status transitions and restarts:

   ```bash
   kubectl get pods -n capstone-lab -w
   ```

   Check the logs of the container to inspect API status codes:

   ```bash
   kubectl logs -l app=capstone-web -n capstone-lab -f
   ```

   Query the cluster events to locate the liveness probe failure warnings:

   ```bash
   kubectl get events -n capstone-lab --sort-by='.metadata.creationTimestamp'
   ```

3. **Debug the Ingress Endpoint:**

   Verify the Ingress controller backend target settings:

   ```bash
   kubectl describe ingress capstone-ingress -n capstone-lab
   ```

4. **Apply the Fixed Manifests:**

   Apply the corrected configuration:

   ```bash
   kubectl apply -f phase-4/day-30/manifests/fixed/
   ```

5. **Verify Resolution:**

   Observe the pod status to ensure it transitions to a stable `Running` state without restarts:

   ```bash
   kubectl get pods -n capstone-lab
   ```

   Verify that the container logs now report successful API queries (`HTTP 200`):

   ```bash
   kubectl logs -l app=capstone-web -n capstone-lab
   ```

6. **Clean Up:**

   ```bash
   kubectl delete namespace capstone-lab
   ```

---

[Back to main README.md](../../README.md)
