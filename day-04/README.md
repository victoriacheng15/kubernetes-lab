# Day 04

This day explains how Services provide stable access, DNS-based discovery, and load balancing for ephemeral Pods.

## Concept Overview

In Kubernetes, Pods are ephemeral. When a Pod is rescheduled or restarted, it gets a completely new IP address. If your backend application tried to connect directly to individual frontend Pod IPs, it would break constantly.

Kubernetes solves this using **Services**, a persistent networking abstraction that groups a dynamic set of Pods under a single, stable IP address and DNS name.

## Core Concepts

### Service Types Comparison

| Service Type | Scope | Target Port Access | Use Case |
| --- | --- | --- | --- |
| **ClusterIP** | Internal | Access only inside the cluster | Default type. Private microservice communication (e.g. database, internal API). |
| **NodePort** | External | Access via `<NodeIP>:<NodePort>` on every node | Exposing services externally on static high-range ports (30000-32767). |
| **LoadBalancer** | External | Access via a cloud provider's external load balancer | Standard way to expose web applications to the public internet in cloud environments. |
| **Headless** | Internal | Direct access to individual Pod IPs via DNS | Stateful applications (like database replicas) that need to bypass load balancing. |

### How Service Routing Works

A Service acts as a static gateway. It uses a **Label Selector** to find matching Pods and automatically populates a list of active target IPs called **Endpoints**.

```text
Client request
  ↓
Service (stable IP or DNS)
  ├─ Pod A
  └─ Pod B
```

### DNS and Service Discovery

Kubernetes automatically runs a cluster-wide DNS service called **CoreDNS**. When you create a Service named `my-service` in a namespace named `prod`, CoreDNS automatically creates a stable DNS record matching this format:

```text
my-service.prod.svc.cluster.local
```

Any container inside the cluster can reach this service by simply querying `my-service` (if in the same namespace) or `my-service.prod` (if in a different namespace).

## Checklist

- [ ] Explain why you should never connect directly to a Pod IP address.
- [ ] Describe the difference between ClusterIP and NodePort services.
- [ ] Explain the role of CoreDNS in service discovery.
- [ ] Inspect the active routing targets of a service using `kubectl get endpoints`.
- [ ] Resolve a service name from inside a running container using `nslookup`.

## Lab

In this lab, you will deploy a set of backend web pods, expose them using ClusterIP and NodePort services, and perform DNS lookups from an isolated diagnostic pod.

### Steps

1. **Deploy the Web Application:**
   Apply the Deployment manifest (creates 2 nginx pods serving on port 80):

   ```bash
   kubectl apply -f day-04/manifests/01-deployment.yaml
   ```

2. **Expose internally via ClusterIP:**
   Apply the ClusterIP Service manifest:

   ```bash
   kubectl apply -f day-04/manifests/02-clusterip.yaml
   ```

   Verify the Service and check its stable internal IP:

   ```bash
   kubectl get service web-internal
   ```

   Inspect the active backend Pod IPs that the Service discovered:

   ```bash
   kubectl get endpoints web-internal
   ```

3. **Expose externally via NodePort:**
   Apply the NodePort Service manifest:

   ```bash
   kubectl apply -f day-04/manifests/03-nodeport.yaml
   ```

   Verify the Service and locate the high-range port assigned to it:

   ```bash
   kubectl get service web-external
   ```

4. **Verify DNS Resolution from Inside the Cluster:**
   To test DNS, run a temporary diagnostic container in your cluster:

   ```bash
   kubectl run dns-test --rm -i --tty --image=busybox:1.36 --restart=Never -- sh
   ```

   *Note: If you run into scheduling or shell issues, you can execute these diagnostic commands directly within the pod shell once it boots:*

   Inside the busybox shell, test internal DNS resolution for your Service:

   ```bash
   nslookup web-internal
   ```

   Test fetching the webpage using the stable service name:

   ```bash
   wget -qO- http://web-internal
   ```

   Exit the diagnostic pod:

   ```bash
   exit
   ```

5. **Clean Up:**
   Delete all resources created during this lab:

   ```bash
   kubectl delete -f day-04/manifests/
   ```

---

[Back to main README.md](../README.md)
