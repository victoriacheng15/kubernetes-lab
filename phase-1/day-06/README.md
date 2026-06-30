# Day 06

This day covers namespace-based governance with ResourceQuotas and LimitRanges to protect shared clusters.

## Concept Overview

In a shared Kubernetes cluster, multiple teams, applications, or environments (like dev, staging, prod) run on the same physical machines. Without governance, a single misconfigured container with a memory leak or a CPU loop can consume all host resources, starving other applications on the node. This is called the **noisy-neighbor problem**.

Kubernetes solves this using three features to isolate and control resources:

1. **Namespaces:** Logical virtual clusters inside a physical cluster that provide scope for names and authorization.
2. **ResourceQuotas:** Namespace-level constraints that limit the *aggregate* resource consumption (e.g. total CPU, total Memory, total Pod count) across the entire namespace.
3. **LimitRanges:** Container-level constraints that enforce *minimum, maximum, and default* resource requests and limits on individual Pods created in the namespace.

## Core Concepts

### ResourceQuotas vs. LimitRanges

| Aspect | ResourceQuota | LimitRange |
| --- | --- | --- |
| **Scope** | Namespace-level (aggregates all Pods) | Container / Pod-level (individual workloads) |
| **Protects against** | The entire team consuming more than their fair share of the cluster | A single developer forgetting to set resource limits on their container |
| **Typical Rules** | "This namespace cannot exceed 4 CPUs or 8Gi of RAM in total" | "Every container must have between 50m and 1 CPU, and defaults to 100m" |
| **Rejection Timing** | Workload creation is blocked once the aggregate quota is saturated | Workload creation is blocked instantly if a single container violates boundaries |

### Resource Governance in action

The diagram below shows how the logical Namespace wraps your workloads, while ResourceQuotas guard the boundary and LimitRanges inject default safety valves:

```text
Cluster
└─ Namespace: dev-team
   ├─ ResourceQuota → enforces namespace boundary
   ├─ LimitRange → sets default container limits
   ├─ Pod A → 512Mi request
   └─ Pod B → default 256Mi limit
```

### Common Resource Types Recap

As you complete these core foundational steps, here is a quick, factual summary of the common Kubernetes resource types covered so far:

1. **Namespace** - Virtual boundary for separating environments.
2. **Pod** - The smallest execution unit running your containers.
3. **Deployment** - Manages stateless applications and updates.
4. **StatefulSet** - Manages databases and stateful applications with persistent storage.
5. **Service** - Network router providing stable access to Pods.
6. **Ingress** - External routing engine to expose Services.
7. **ConfigMap** - Configuration settings injected into containers.
8. **Secret** - Sensitive credentials (passwords, tokens, certificates) injected into containers.
9. **PersistentVolumeClaim (PVC)** - Request for persistent disk storage.
10. **ServiceAccount & RBAC** - Pod identity and permissions to govern API access.

## Checklist

- [ ] Explain how Namespaces provide logical isolation in a shared cluster.
- [ ] Describe the difference between ResourceQuotas and LimitRanges.
- [ ] Create a custom namespace, ResourceQuota, and LimitRange.
- [ ] Deploy a compliant pod and observe how a LimitRange automatically injects default CPU/Memory requests if they are unspecified.
- [ ] Attempt to deploy an oversized pod and observe how the API server rejects the creation request due to quota saturation.

## Lab

In this lab, you will create a isolated namespace, apply resource boundaries, and observe how Kubernetes automatically intercepts and rejects non-compliant workloads.

### Steps

1. **Create the Namespace and Boundaries:**
   Apply the namespace, ResourceQuota, and LimitRange manifests:

   ```bash
   kubectl apply -f phase-1/day-06/manifests/01-namespace.yaml
   kubectl apply -f phase-1/day-06/manifests/02-resourcequota.yaml
   ```

   Apply the LimitRange manifest specifically to your namespace:

   ```bash
   kubectl apply -f phase-1/day-06/manifests/03-limitrange.yaml
   ```

   Verify they are active in the `dev-team` namespace:

   ```bash
   kubectl get resourcequotas -n dev-team
   kubectl get limitranges -n dev-team
   ```

2. **Deploy a Compliant Pod:**
   Apply the compliant Pod manifest:

   ```bash
   kubectl apply -f phase-1/day-06/manifests/04-pod-compliant.yaml
   ```

   Verify the Pod is running:

   ```bash
   kubectl get pods -n dev-team
   ```

3. **Verify LimitRange Default Injections:**
   Inspect the compliant Pod details using YAML output:

   ```bash
   kubectl get pod compliant-pod -n dev-team -o yaml
   ```

   Scroll to `spec.containers[0].resources`. Notice that even though our manifest did not define CPU and memory requests/limits, the **LimitRange automatically injected the default values** (100m CPU and 256Mi Memory requests) at admission time!

4. **Test Quota Enforcement (The Oversized Pod):**
   Attempt to apply the oversized Pod manifest (requests 4 CPU and 8Gi RAM, which exceeds the aggregate namespace quota):

   ```bash
   kubectl apply -f phase-1/day-06/manifests/05-pod-oversized.yaml
   ```

   *Expected Outcome:* The API server will reject the command instantly and print an error message similar to:

   ```text
   Error from server (Forbidden): error when creating "phase-1/day-06/manifests/05-pod-oversized.yaml": pods "oversized-pod" is forbidden: exceeded quota: dev-quota, requested: limits.cpu=4,limits.memory=8Gi, requests.cpu=4,requests.memory=8Gi, used: limits.cpu=500m,limits.memory=512Mi, requests.cpu=250m,requests.memory=256Mi, limited: limits.cpu=2,limits.memory=2Gi, requests.cpu=1,requests.memory=1Gi
   ```

   This proves that the ResourceQuota effectively protected your cluster from resource starvation before the workload could even be scheduled!

5. **Clean Up:**
   Delete the namespace (which automatically deletes all resources, quotas, limitranges, and pods inside it):

   ```bash
   kubectl delete namespace dev-team
   ```

---

[Back to main README.md](../../README.md)
