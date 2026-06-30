# Day 18

This day covers configuring Horizontal Pod Autoscaling (HPA) to scale workloads dynamically based on resource usage.

## Concept Overview

The Horizontal Pod Autoscaler dynamically scales the number of Pod replicas based on target CPU or memory utilization.

```text
                  ┌───────────────────────────────┐
                  │   Metrics Server (CPU/Mem)    │
                  └───────────────┬───────────────┘
                                  │
                                  ▼ (polls every 15s)
┌──────────────┐    adjust     ┌──────────────┐
│  Deployment  │ ◄──────────── │     HPA      │
└──────┬───────┘               └──────────────┘
       │
       ├──► [ Pod 1 ]
       ├──► [ Pod 2 ]
       └──► [ Pod N ] (dynamic replica count)
```

---

## Core Concepts

1. **Metrics Server:** A cluster-wide aggregator of resource usage data. HPA requires Metrics Server to query CPU and Memory utilization.
2. **Resource Requests:** HPA calculates resource utilization as a percentage of the requested resource. For example, if a Pod requests 200m CPU and uses 100m CPU, the utilization is 50%. HPAs will not work unless Pod templates define resource requests.
3. **Autoscaling Algorithm:** The HPA controller calculates the target number of replicas using this formula:
   `desiredReplicas = ceil[currentReplicas * ( currentMetricValue / desiredMetricValue )]`
4. **Cooldown / Stabilization Window:** Used to prevent "flapping" (rapid scaling up and down in response to transient metric fluctuations).

---

## Checklist

- [ ] Ensure metrics-server is running (or mock metrics check).
- [ ] Create a dedicated namespace for the HPA lab.
- [ ] Deploy a CPU-intensive web service with CPU requests defined.
- [ ] Create a HorizontalPodAutoscaler pointing to the web service.
- [ ] Deploy a load generator and observe HPA scale-up behavior.
- [ ] Terminate the load generator and observe HPA scale-down behavior.

---

## Lab

In this lab, you will deploy a CPU-intensive PHP application, define an HPA that targets 50% CPU utilization, run a load generator to trigger scaling, and verify the autoscaling results.

### Steps

1. **Verify Metrics Server:**

   First, check if your cluster has `metrics-server` installed:

   ```bash
   kubectl top nodes
   ```

   If this command returns resource usage statistics, metrics-server is running. If not, you will need to install it to see the HPA actively fetch metrics:

   ```bash
   kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
   ```

2. **Create the Namespace:**

   ```bash
   kubectl apply -f phase-3/day-18/manifests/01-namespace.yaml
   ```

3. **Deploy the Web Server and Service:**

   ```bash
   kubectl apply -f phase-3/day-18/manifests/02-deployment.yaml
   kubectl apply -f phase-3/day-18/manifests/03-service.yaml
   ```

4. **Deploy the HPA:**

   ```bash
   kubectl apply -f phase-3/day-18/manifests/04-hpa.yaml
   ```

   Verify HPA initialization:

   ```bash
   kubectl get hpa -n hpa-lab
   ```

   *Note:* It may take a minute or two for the HPA to show the current target usage instead of `<unknown>`.

5. **Generate Load:**

   Start a pod in the background to send requests continuously to the web service:

   ```bash
   kubectl apply -f phase-3/day-18/manifests/05-load-generator.yaml
   ```

6. **Monitor HPA and Pod Scaling:**

   Run a watch command to monitor the replica count and resource utilization:

   ```bash
   kubectl get hpa php-apache -n hpa-lab -w
   ```

   *Expected Outcome:* Within a few minutes, the CPU usage will spike well above the 50% target. The HPA will scale up the deployment replicas from 1 to 3, and eventually higher (up to a limit of 5) to distribute the load.

   Verify the current replica count:

   ```bash
   kubectl get deployment php-apache -n hpa-lab
   ```

7. **Remove Load and Observe Scale-Down:**

   Delete the load generator:

   ```bash
   kubectl delete pod load-generator -n hpa-lab
   ```

   Monitor the HPA again:

   ```bash
   kubectl get hpa php-apache -n hpa-lab -w
   ```

   *Expected Outcome:* Once CPU usage drops to 0%, the HPA will scale the replicas back down to 1. Note that scale-down has a default stabilization window (often 5 minutes) to prevent immediate thrashing, so it will take a few minutes to scale back down.

8. **Clean Up:**

   ```bash
   kubectl delete namespace hpa-lab
   ```

---

[Back to main README.md](../../README.md)
