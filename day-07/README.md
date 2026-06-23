# Day 07

This project combines the core foundation concepts into a two-tier guestbook-style application you can deploy and troubleshoot.

## Concept Overview

Congratulations on completing **Phase 1: Core Foundations**! You have covered:

* Day 01: Cluster Architecture & Control Plane
* Day 02: Pod Lifecycle & Init Containers
* Day 03: Deployments, ReplicaSets & Rollouts
* Day 04: Services & Service Discovery
* Day 05: ConfigMaps & Secrets
* Day 06: Namespaces, ResourceQuotas & LimitRanges

Today is a practical project day designed to consolidate all of these concepts into a single, cohesive, two-tier application.

## Core Concepts

### Project Architecture

You will deploy a two-tier guestbook application:

1. **Frontend App (Python Flask):** A stateless web application that counts visitor hits. It reads non-sensitive settings from a ConfigMap, sensitive credentials from a Secret, and connects to a backend database.
2. **Backend Database (Redis):** A key-value store that persists visitor counts. It runs in the same namespace, uses a stable Service, and is secured via password authentication.

```text
Namespace: phase1-project
├─ ResourceQuota / LimitRange
├─ ConfigMap / Secret
├─ Web Deployment → Web NodePort Service → External client
└─ Redis Deployment → Redis ClusterIP Service
       Web Deployment → Redis Service
```

### Troubleshooting Guide (Common Failures)

During deployment, you may encounter these common operational roadblocks. Use your troubleshooting toolbelt (`kubectl describe`, `kubectl logs`, and `kubectl get pods -w`) to solve them:

1. **`CrashLoopBackOff` on the Frontend:**
   * *Possible Cause:* The frontend container started before the Redis database was reachable, or the password was incorrect.
   * *Solution:* Verify that the `REDIS_PASSWORD` environment variable matches between the Secret and both deployments, and ensure the frontend container utilizes the correct service DNS name.

2. **`Forbidden` API Rejections:**
   * *Possible Cause:* Your container resource requests or limits violate the namespace's `LimitRange` or exceed the aggregate `ResourceQuota`.
   * *Solution:* Check the LimitRange boundaries and adjust your Pod resource spec to fit.

3. **`ErrImagePull` or `ImagePullBackOff`:**
   * *Possible Cause:* Typo in the image name or tag.
   * *Solution:* Inspect the pod using `kubectl describe pod` and verify the image names in your manifests.

## Checklist

* [ ] Create an isolated namespace `phase1-project`.
* [ ] Apply resource boundaries (`ResourceQuota` and `LimitRange`) to govern the namespace.
* [ ] Deploy a ConfigMap and an Opaque Secret to hold database configurations and credentials.
* [ ] Deploy the Redis database backend and expose it internally via a stable ClusterIP Service on port 6379.
* [ ] Deploy the Python Flask web application and expose it externally via a NodePort Service on port 30080.
* [ ] Access the application using your browser or curl, and verify that the hit counter increments successfully.
* [ ] Troubleshoot any scheduling, network routing, or credential mismatches that occur during deployment.

## Lab

To execute the project, navigate to the `day-07` directory and apply the manifests in order:

### Steps

1. **Initialize the Governance Plane:**

   ```bash
   kubectl apply -f day-07/manifests/01-namespace.yaml
   kubectl apply -f day-07/manifests/02-resourcequota.yaml
   kubectl apply -f day-07/manifests/03-limitrange.yaml
   ```

2. **Apply Configurations and Secrets:**

   ```bash
   kubectl apply -f day-07/manifests/04-configmap.yaml
   kubectl apply -f day-07/manifests/05-secret.yaml
   ```

3. **Deploy the Database Tier:**

   ```bash
   kubectl apply -f day-07/manifests/06-redis.yaml
   ```

   Verify that Redis is healthy and its internal endpoint is active:

   ```bash
   kubectl get pods -n phase1-project
   kubectl get service -n phase1-project
   ```

4. **Deploy the Frontend Web Tier:**

   ```bash
   kubectl apply -f day-07/manifests/07-web-app.yaml
   ```

   Monitor the deployment in real-time until all pods are running:

   ```bash
   kubectl get pods -n phase1-project -w
   ```

5. **Verify the Application:**
   Locate your cluster IP or NodePort and test the application using `curl` from your host terminal:

   ```bash
   curl http://localhost:30080
   ```

   Run the command multiple times and verify that the hit count increments, proving that the frontend is successfully writing to the backend Redis cache over the virtual service network!

6. **Verify the Database State Directly:**
   Expose and query the Redis backend directly to verify that the visitor count is successfully stored in memory. Run the following automated single-line command from your host terminal:

   ```bash
   kubectl exec -it -n phase1-project $(kubectl get pods -n phase1-project -l app=database -o jsonpath='{.items[0].metadata.name}') -- redis-cli -a projectpassword get hits
   ```

   Observe that it returns the exact raw visitor count matching your curl outputs, validating database persistence!

7. **Clean Up:**
   Delete the namespace to remove all project resources:

   ```bash
   kubectl delete namespace phase1-project
   ```

---

[Back to main README.md](../README.md)
