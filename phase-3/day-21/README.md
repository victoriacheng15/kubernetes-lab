# Day 21

This project combines access control, health checks, batch workloads, autoscaling, and diagnostics into a secure, observable, and autoscaling application.

## Concept Overview

Congratulations on completing **Phase 3: Security & Operations**! You have covered:

* Day 15: RBAC, ServiceAccounts, Roles, ClusterRoles, and bindings
* Day 16: Liveness, readiness, and startup probes
* Day 17: Jobs and CronJobs
* Day 18: Horizontal Pod Autoscaler (HPA)
* Day 19: Correlate logs, metrics, events, pod conditions, and node conditions
* Day 20: Debug containers with exec and ephemeral containers

Today is a practical project day designed to consolidate all of these operational concepts into a single deployment.

---

## Core Concepts

### Project Architecture

You will deploy a secure application that queries the Kubernetes API server using its ServiceAccount identity, exposed to traffic with a Service, scaled dynamically with an HPA, and audited periodically using a CronJob.

1. **Least Privilege Identity:** The app must run under a custom `ServiceAccount` and have read-only access to ConfigMaps in its namespace via a `Role` and `RoleBinding`.
2. **Dynamic Scaling:** A `HorizontalPodAutoscaler` must target the deployment and maintain 50% CPU utilization, scaling replicas from 1 to 5.
3. **Scheduled Auditing:** A `CronJob` must run once per minute to audit the configuration state by calling the Kubernetes API.

```text
Namespace: project-3
├─ ServiceAccount (app-sa) ⇄ RoleBinding ⇄ Role (config-reader)
├─ App Deployment (secure-app) ⇄ Startup Probe ⇄ HPA (50% target)
└─ CronJob (config-audit) (runs once per minute using app-sa)
```

### Troubleshooting Guide (Common Failures)

The initial manifests in `day-21/manifests/broken/` contain three deliberate configuration errors. Use your debugging tools (`kubectl logs`, `kubectl describe`, and events) to resolve them:

1. **Pod stuck in a restart loop / CrashLoopBackOff (Startup Probe Misconfiguration):**
   * *Possible Cause:* The startup probe checks `/tmp/started`, but the application script only touches `/tmp/ready` upon successful API authorization.
   * *Solution:* Inspect `kubectl describe pod -n project-3`. Notice that the startup probe is checking the wrong path. Modify the startup probe to target `/tmp/ready`.

2. **HPA fails to fetch metrics or scale (Missing Resource Requests):**
   * *Possible Cause:* The HPA requires resource requests on target Pod containers to calculate the utilization percentage.
   * *Solution:* Check HPA status with `kubectl get hpa -n project-3`. You will see `<unknown>` under targets. Add a `resources.requests` section to the deployment's container template.

3. **Application API calls fail with HTTP 403 Forbidden (RBAC Binding Mismatch):**
   * *Possible Cause:* The RoleBinding binds the `config-reader` Role to a non-existent ServiceAccount name instead of the application's actual ServiceAccount.
   * *Solution:* Check the container logs with `kubectl logs -n project-3 -l app=secure-app`. Notice the 403 responses. Inspect the RoleBinding definition and update the subject name to `app-sa`.

### Manifest Differences (Broken vs Fixed)

<details>
<summary>Reveal Manifest Differences and Explanations</summary>

Here is a detailed comparison of the changes made between the `broken` and `fixed` manifests:

**1. RoleBinding Alignment (`02-serviceaccount-rbac.yaml`)**

```diff
--- day-21/manifests/broken/02-serviceaccount-rbac.yaml
+++ day-21/manifests/fixed/02-serviceaccount-rbac.yaml
@@ -21,2 +21,2 @@
-    name: wrong-sa
+    name: app-sa
```

**Why this change is required:**

* The broken manifest bound the permissions to `wrong-sa`. The application runs using the `app-sa` identity, meaning API requests were unauthorized (returning HTTP 403). Changing this to `app-sa` ensures authorization.

**2. Probe Target & Resources Configuration (`03-deployment.yaml`)**

```diff
--- day-21/manifests/broken/03-deployment.yaml
+++ day-21/manifests/fixed/03-deployment.yaml
@@ -31,2 +31,2 @@
-                - /tmp/started
+                - /tmp/ready
@@ -38,2 +38,5 @@
             limits:
               cpu: 200m
               memory: 128Mi
+            requests:
+              cpu: 100m
+              memory: 64Mi
```

**Why this change is required:**

* **Startup Probe:** The application script creates `/tmp/ready` upon successful authentication. Checking `/tmp/started` caused the startup probe to fail, causing Kubernetes to terminate and restart the pod.
* **HPA Resource Requests:** HPA cannot compute percentage-based utilization without explicit `requests` definitions. Adding CPU requests allows metrics calculations to succeed.

</details>

---

## Checklist

* [ ] Create the `project-3` namespace.
* [ ] Deploy the RBAC rules and ServiceAccount.
* [ ] Deploy the application deployment, Service, HPA, and auditing CronJob.
* [ ] Correlate logs and events to diagnose the restart loop and API 403 errors.
* [ ] Fix the configuration errors and verify the application achieves a stable running state.
* [ ] Validate that the HPA successfully polls resource metrics.

---

## Lab

### Part 1: Deploy and Diagnose the Broken App

1. **Apply the Broken Manifests:**

   ```bash
   kubectl apply -f day-21/manifests/broken/01-namespace.yaml
   kubectl apply -f day-21/manifests/broken/02-serviceaccount-rbac.yaml
   kubectl apply -f day-21/manifests/broken/03-deployment.yaml
   kubectl apply -f day-21/manifests/broken/04-service.yaml
   kubectl apply -f day-21/manifests/broken/05-hpa.yaml
   kubectl apply -f day-21/manifests/broken/06-cronjob.yaml
   ```

2. **Inspect the Status and Logs:**

   Monitor the pod lifecycle:

   ```bash
   kubectl get pods -n project-3 -w
   ```

   Look at the pod events to identify the probe failure:

   ```bash
   kubectl describe pod -n project-3 -l app=secure-app
   ```

   Check the container log output to find the API client authorization failure:

   ```bash
   kubectl logs -n project-3 -l app=secure-app
   ```

3. **Verify HPA Metrics Failure:**

   ```bash
   kubectl get hpa secure-app-hpa -n project-3
   ```

   *Expected Outcome:* The target column shows `<unknown>/50%` because the deployment's container has no CPU requests defined.

4. **Clean Up Broken Resources:**

   ```bash
   kubectl delete namespace project-3
   ```

### Part 2: Deploy and Verify the Fixed App

1. **Apply the Fixed Manifests:**

   ```bash
   kubectl apply -f day-21/manifests/fixed/01-namespace.yaml
   ```

   Wait a few seconds for the namespace to initialize, then apply the remaining configuration:

   ```bash
   kubectl apply -f day-21/manifests/fixed/02-serviceaccount-rbac.yaml
   kubectl apply -f day-21/manifests/fixed/03-deployment.yaml
   kubectl apply -f day-21/manifests/fixed/04-service.yaml
   kubectl apply -f day-21/manifests/fixed/05-hpa.yaml
   kubectl apply -f day-21/manifests/fixed/06-cronjob.yaml
   ```

2. **Confirm App Stability & Logs:**

   Monitor the pod until it is `Running` and stable:

   ```bash
   kubectl get pods -n project-3
   ```

   Verify successful API server calls in logs:

   ```bash
   kubectl logs -n project-3 -l app=secure-app
   ```

   *Expected Outcome:* You should see `API Check: ConfigMaps HTTP Status 200`.

3. **Confirm HPA Metrics Collection:**

   Wait about a minute for metrics collection to populate, then run:

   ```bash
   kubectl get hpa secure-app-hpa -n project-3
   ```

   *Expected Outcome:* The target column shows the active usage percentage (e.g., `0%/50%`).

4. **Clean Up:**

   ```bash
   kubectl delete namespace project-3
   ```

---

[Back to main README.md](../README.md)
