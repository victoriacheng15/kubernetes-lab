# Day 19

This day covers diagnosing and troubleshooting workload issues by correlating logs, metrics, events, pod conditions, and node conditions.

## Concept Overview

Effective troubleshooting in Kubernetes requires collecting and correlating different signals.

```text
           [ Troubleshooting Inputs ]
                       │
     ┌─────────────────┼─────────────────┐
     ▼                 ▼                 ▼
[ Events ]        [ Conditions ]      [ Logs & Metrics ]
(lifecycle step)   (Pod / Node status) (runtime behavior)
```

---

## Core Concepts

1. **Events:** Temporary cluster occurrences (e.g., scheduling decisions, image pulls, container crashes, OOM events). Viewable using `kubectl get events` or `kubectl describe`.
2. **Pod/Node Conditions:** Status flags indicating current states (e.g., `PodScheduled`, `Initialized`, `ContainersReady`, `Ready`).
3. **Logs:** The standard output and standard error streams from containerized applications, retrieved via `kubectl logs`.
4. **Metrics:** Current CPU and memory utilization data retrieved via `kubectl top`.
5. **Common Pod Failure States:**
   - **OOMKilled:** The container was terminated because it exceeded its memory limit.
   - **CreateContainerConfigError / CreateContainerError:** A failure occurred when preparing config requirements (such as missing ConfigMaps or Secrets).
   - **CrashLoopBackOff:** The container starts, fails, and restarts repeatedly, with increasing delay between attempts.

---

## Checklist

- [ ] Create a dedicated namespace for the diagnostics lab.
- [ ] Deploy a pod that triggers an OOMKilled status.
- [ ] Inspect pod conditions and events to identify the root cause of the OOM crash.
- [ ] Deploy a pod with a missing configuration dependency.
- [ ] Correlate the resulting configuration error using describe commands and events.

---

## Lab

In this lab, you will deploy two intentionally misconfigured workloads to practice diagnosing issues using different Kubernetes diagnostic signals.

### Steps

1. **Create the Namespace:**

   ```bash
   kubectl apply -f phase-3/day-19/manifests/01-namespace.yaml
   ```

2. **Deploy the OOM Workload:**

   ```bash
   kubectl apply -f phase-3/day-19/manifests/02-oom-pod.yaml
   ```

3. **Diagnose the OOM Crash:**

   Wait a few seconds, then check the Pod status:

   ```bash
   kubectl get pods -n diagnostics-lab
   ```

   *Expected Outcome:* The pod status will be `OOMKilled`.

   Inspect the detailed status:

   ```bash
   kubectl get pod oom-pod -n diagnostics-lab -o yaml
   ```

   Look under `status.containerStatuses[0].state.terminated`. You will see `reason: OOMKilled` and `exitCode: 137`.

   Check the events related to the pod:

   ```bash
   kubectl describe pod oom-pod -n diagnostics-lab
   ```

   Check the logs of the container before it was terminated:

   ```bash
   kubectl logs oom-pod -n diagnostics-lab
   ```

   *Expected Outcome:* The logs print "Allocating memory..." and then stop abruptly without executing the final echo.

4. **Deploy the Config Error Workload:**

   ```bash
   kubectl apply -f phase-3/day-19/manifests/03-config-error-pod.yaml
   ```

5. **Diagnose the Config Error:**

   Check the Pod status:

   ```bash
   kubectl get pods -n diagnostics-lab
   ```

   *Expected Outcome:* The pod status will show `CreateContainerConfigError`.

   Describe the pod:

   ```bash
   kubectl describe pod config-error-pod -n diagnostics-lab
   ```

   Look at the Events section at the bottom.

   *Expected Outcome:* You will see a `Warning` event with `Reason: Failed` and a message stating that the ConfigMap "non-existent-config" was not found.

   Check Pod conditions:

   ```bash
   kubectl get pod config-error-pod -n diagnostics-lab -o jsonpath='{.status.conditions}'
   ```

   *Expected Outcome:* The `Ready` condition is `False` with the reason `ContainersNotReady`.

6. **Clean Up:**

   ```bash
   kubectl delete namespace diagnostics-lab
   ```

---

[Back to main README.md](../../README.md)
