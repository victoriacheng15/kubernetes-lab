# Day 16

This day covers configuring liveness, readiness, and startup probes to manage container lifecycles and application health.

## Concept Overview

Kubernetes uses probes to monitor container health and control traffic routing.

```text
[ Pod Startup ] ──► [ Startup Probe ]
                          │ (Failure: restart pod)
                          ▼ (Success)
               ┌──────────┴──────────┐
               ▼                     ▼
       [ Liveness Probe ]    [ Readiness Probe ]
               │                     │
       (Fail: restart pod)   (Fail: remove from Service endpoints)
```

---

## Core Concepts

1. **Liveness Probe:** Determines if a container needs to be restarted. If a liveness probe fails, Kubernetes kills the container and applies its restart policy.
2. **Readiness Probe:** Determines if a container is ready to accept network traffic. If a readiness probe fails, the endpoints controller removes the Pod IP from the endpoints of all Services matching the Pod.
3. **Startup Probe:** Disables liveness and readiness checks during container startup. Useful for legacy or slow-starting applications to prevent premature restarts.
4. **Probe Mechanism Types:**
   - **exec:** Executes a command inside the container. Exit status 0 is success.
   - **httpGet:** Performs an HTTP GET request against the container IP. Status code between 200 and 399 is success.
   - **tcpSocket:** Performs a TCP check against the container port. Open port is success.
   - **grpc:** Performs a gRPC health check.

---

## Checklist

- [ ] Create a dedicated namespace for the probes lab.
- [ ] Configure and observe a failing liveness probe that triggers a container restart.
- [ ] Configure and observe a readiness probe that controls traffic routing via a Service.
- [ ] Configure and observe a startup probe that protects a slow-starting container.

---

## Lab

In this lab, you will deploy pods with different probe configurations and observe how Kubernetes responds to probe failures and successes.

### Steps

1. **Create the Namespace:**

   ```bash
   kubectl apply -f day-16/manifests/01-namespace.yaml
   ```

2. **Deploy the Liveness Probe Pod:**

   ```bash
   kubectl apply -f day-16/manifests/02-liveness-pod.yaml
   ```

3. **Monitor the Liveness Pod:**

   ```bash
   kubectl get pods -n probes-lab -w
   ```

   *Expected Outcome:* The pod starts as healthy, but after 30 seconds, it will fail the liveness check (since `/tmp/healthy` is deleted). You will see the container restarts count increment.

   Verify this using `kubectl describe`:

   ```bash
   kubectl describe pod liveness-pod -n probes-lab
   ```

   Look for events showing "Unhealthy" and the container being restarted.

4. **Deploy the Readiness Pod and Service:**

   ```bash
   kubectl apply -f day-16/manifests/03-readiness-pod.yaml
   kubectl apply -f day-16/manifests/04-service.yaml
   ```

5. **Observe Service Endpoints During Startup:**

   Check the endpoint slices immediately after deployment:

   ```bash
   kubectl get endpointslice -l kubernetes.io/service-name=readiness-service -n probes-lab
   ```

   *Expected Outcome:* The endpoint slice lists no target IP addresses because the container sleeps for 20 seconds before creating `/tmp/ready`.

   After 20-30 seconds, run the command again:

   ```bash
   kubectl get endpointslice -l kubernetes.io/service-name=readiness-service -n probes-lab
   ```

   *Expected Outcome:* The Pod's IP address appears under the list of endpoints once the readiness probe succeeds.

6. **Deploy the Startup Probe Pod:**

   ```bash
   kubectl apply -f day-16/manifests/05-startup-pod.yaml
   ```

7. **Monitor the Startup Pod:**

   ```bash
   kubectl get pod startup-pod -n probes-lab -w
   ```

   *Expected Outcome:* The pod starts up and becomes ready without restarting, even though the startup process takes 30 seconds. The startup probe allows up to 60 seconds (30 attempts * 2 seconds) before failing.

8. **Clean Up:**

   ```bash
   kubectl delete namespace probes-lab
   ```

---

[Back to main README.md](../README.md)
