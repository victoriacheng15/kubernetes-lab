# Project 4: Recover a Broken Cluster and Restore Application Availability

This project tests your ability to troubleshoot multi-tier service communication, identify NetworkPolicy isolation, diagnose Service port routing bugs, and correct container mount path configurations.

## Project Architecture

```mermaid
graph TD
    subgraph "cluster-recovery Namespace"
        Frontend["pod/frontend (client)"]
        Service["service/redis-svc (Port: 6379)"]
        NetworkPolicy["networkpolicy/redis-policy"]
        Database["pod/redis (database)"]
    end

    Frontend ──►|"TCP connection (Blocked by default)"| Service
    Service ──►|"TargetPort: 6379"| Database
    NetworkPolicy ──►|"Filters Ingress"| Database
```

---

## Troubleshooting Guide

The initial configuration deployed in the `broken/` directory contains three distinct network and configuration errors:

### Error 1: NetworkPolicy Isolation

* **Symptom:** The frontend container logs show repeated errors: `ERROR: Connection timeout connecting to Redis database.`
* **Root Cause:** The `redis-policy` NetworkPolicy specifies an ingress rule allowing traffic only from pods with the label `role: web-wrong`. However, the frontend deployment pods are labeled with `role: frontend`. Because the selector does not match, all ingress traffic to the Redis database is dropped.
* **Resolution:** Modify the `ingress.from.podSelector.matchLabels` in [02-networkpolicy.yaml](manifests/broken/02-networkpolicy.yaml) to target the correct frontend label: `role: frontend`.

### Error 2: Incorrect Service TargetPort Mapping

* **Symptom:** Even if the NetworkPolicy is bypassed or updated, traffic to `redis-svc` fails to connect.
* **Root Cause:** The `redis-svc` Service configuration defines a client port of `6379` but forwards traffic to a `targetPort` of `9379`. The Redis container is listening on the standard port `6379`, meaning all routed requests are sent to an inactive port.
* **Resolution:** Edit `targetPort` in [03-service.yaml](manifests/broken/03-service.yaml) to map directly to port `6379`.

### Error 3: Misaligned Volume Mount Path

* **Symptom:** The database runs, but it fails to save state or persist data correctly on container restarts because the directory is misaligned.
* **Root Cause:** The Redis container expects its datastore directory to be mounted at `/data`. However, the deployment's volume mount is mapped to `/data-wrong`.
* **Resolution:** Update the `mountPath` in [04-redis.yaml](manifests/broken/04-redis.yaml) to `/data`.

---

## Manifest Differences

<details>
<summary>Click to view manifest differences</summary>

Below is a comparison of the key changes between the broken and fixed files:

### NetworkPolicy (02-networkpolicy.yaml)

```diff
 -              role: web-wrong
 +              role: frontend
```

### Service (03-service.yaml)

```diff
 -    - port: 6379
 -      targetPort: 9379
 +    - port: 6379
 +      targetPort: 6379
```

### Redis Deployment (04-redis.yaml)

```diff
 -            - name: db-data
 -              mountPath: /data-wrong
 +            - name: db-data
 +              mountPath: /data
```

</details>

---

## Lab Steps

1. **Deploy the Broken State:**

   Deploy the initial set of manifests containing the configuration bugs:

   ```bash
   kubectl apply -f phase-4/day-29/manifests/broken/01-namespace.yaml
   kubectl apply -f phase-4/day-29/manifests/broken/
   ```

2. **Diagnose Workload Failures:**

   List the pods in the namespace:

   ```bash
   kubectl get pods -n cluster-recovery
   ```

   Check the logs of the frontend client to verify the connection failure:

   ```bash
   kubectl logs -l role=frontend -n cluster-recovery -f
   ```

   *Expected Outcome:* Logs will show connection timeouts to the database.

3. **Debug the Network Policy and Service:**

   Verify if the NetworkPolicy or Service port targets are causing the issue:
   * Describe the network policy: `kubectl describe networkpolicy redis-policy -n cluster-recovery`
   * Check the endpoints of the redis service: `kubectl get endpoints redis-svc -n cluster-recovery`
   * Compare the Service's `targetPort` against the port exposed in the Redis pod/deployment spec.

4. **Apply the Fixed Manifests:**

   Apply the corrected configuration:

   ```bash
   kubectl apply -f phase-4/day-29/manifests/fixed/
   ```

5. **Verify Resolution:**

   Observe the frontend client logs to confirm that the connection is now successfully established:

   ```bash
   kubectl logs -l role=frontend -n cluster-recovery -f
   ```

   *Expected Outcome:* The log output changes to: `SUCCESS: Connected to Redis database.`

6. **Clean Up:**

   ```bash
   kubectl delete namespace cluster-recovery
   ```

---

[Back to main README.md](../../README.md)
