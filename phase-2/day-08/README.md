# Day 08

This day explains resource requests, limits, and QoS classes, and how Kubernetes enforces CPU and memory behavior.

## Concept Overview

In a shared Kubernetes cluster, control plane scheduling and node-level stability depend on how workloads declare their resource requirements. If workloads do not specify their resource needs, the scheduler cannot place pods intelligently, and the node's Kubelet cannot defend critical system services from resource-hungry containers.

Kubernetes governs resource allocation using two primary container-level specifications:

1. **Requests:** The minimum amount of resources (CPU and Memory) that a container requires to run. The Kubernetes scheduler uses requests to find a node with sufficient unallocated resources to host the Pod.
2. **Limits:** The maximum amount of resources that a container is allowed to consume. The node's container runtime enforces these boundaries at execution time.

## Core Concepts

### Resource Behavior: CPU vs. Memory

The Kubelet enforces requests and limits differently depending on whether a resource is compressible or incompressible:

| Resource Type | Compressibility | Over-limit Behavior | Enforcement Mechanism |
| :--- | :--- | :--- | :--- |
| **CPU** | Compressible | Container is throttled (slowed down), but not terminated. | CFS (Completely Fair Scheduler) shares / cgroups |
| **Memory** | Incompressible | Container is terminated immediately via the Out-Of-Memory (OOM) Killer. | kernel OOM-killer / cgroups memory limits |

* **CPU Representation:** Declared in cores or millicores (e.g., `100m` represents 100 millicores or 0.1 of a CPU core).
* **Memory Representation:** Declared in bytes, typically using binary SI units (e.g., `128Mi` for 128 Mebibytes, `1Gi` for 1 Gibibyte).

### Quality of Service (QoS) Classes

Kubernetes dynamically assigns a Quality of Service (QoS) class to every Pod based on the configuration of its container resource requests and limits. The Kubelet uses this QoS class to make eviction decisions when the host node experiences resource pressure.

```text
Pod created
  ├─ All containers define requests and limits?
  │   ├─ yes → Are requests and limits equal for every container?
  │   │   ├─ yes → Guaranteed
  │   │   └─ no  → Burstable
  │   └─ no  → Any requests or limits defined?
  │           ├─ yes → Burstable
  │           └─ no  → BestEffort
```

### The Three QoS Classes

This section maps technical requirements to specific production workloads and settings:

#### 1. Guaranteed (Lowest Eviction Priority)

* **Ideal Workloads:**
  * Stateful Database Engines (PostgreSQL, MySQL, MongoDB, Elasticsearch).
  * Distributed Key-Value Stores (Redis, etcd, Consul).
  * Critical Traffic Ingress and Routing (Ingress Controllers, API Gateways).
* **Example Configuration (Structural Blueprint):**

    ```yaml
    resources:
      requests:
        cpu: "2"
        memory: 4Gi
      limits:
        cpu: "2"
        memory: 4Gi
    ```

    *(Note: CPU and Memory Requests must exactly equal their respective Limits)*
* **Why:** These applications require stable, predictable performance. Setting equal limits prevents CPU throttling, enables CPU pinning (if the node CPU Manager policy is set to static), and ensures the pod is never evicted unless the entire host node is about to fail.

#### 2. Burstable (Medium Eviction Priority)

* **Ideal Workloads:**
  * Stateless Web Services and Microservices (Node.js, Go, Python, Java Spring Boot).
  * Event Queue Consumers and Background Workers (Kafka consumers, RabbitMQ processors).
  * Continuous Integration/Continuous Deployment (CI/CD) runners.
* **Example Configuration (Structural Blueprint):**

    ```yaml
    resources:
      requests:
        cpu: 200m
        memory: 256Mi
      limits:
        memory: 512Mi
    ```

    *(Note: Memory limit is set to handle normal operational spikes, CPU requests are declared for scheduling, but CPU limits are omitted to allow the process to utilize idle node capacity without throttling)*
* **Why:** These services experience variable traffic. Setting a baseline request guarantees they can start and run, while allowing them to expand into idle node capacity. If the node runs low on memory, they can be rescheduled on other nodes without losing user state.

#### 3. BestEffort (Highest Eviction Priority)

* **Ideal Workloads:**
  * Short-lived interactive debug sessions (e.g., `kubectl exec` helpers).
  * Non-critical local development sandboxes and prototypes.
  * Highly fault-tolerant, interruptible batch processing jobs.
* **Example Configuration (Structural Blueprint):**

    ```yaml
    # No resources block defined
    ```

* **Why:** These jobs are entirely disposable. By omitting resource declarations, you allow the scheduler to pack these pods onto any node with remaining physical room. They run completely on free, leftover capacity, with the understanding that they will be terminated immediately if a Guaranteed or Burstable workload requires the resource.

---

## Checklist

* [ ] Define the difference between resource requests and limits.
* [ ] List the three Kubernetes QoS classes and explain the assignment logic.
* [ ] Deploy and verify a Guaranteed Pod.
* [ ] Deploy and verify a Burstable Pod.
* [ ] Deploy and verify a BestEffort Pod.
* [ ] Simulate memory over-allocation to trigger and observe an Out-Of-Memory (OOMKilled) event.

---

## Lab

In this lab, you will create a dedicated namespace, deploy Pods representing each QoS class, verify how Kubernetes classifies them, and observe runtime limit enforcement by intentionally triggering an Out-Of-Memory error.

### Steps

1. **Create the Namespace:**
    Apply the namespace manifest:

    ```bash
    kubectl apply -f phase-2/day-08/manifests/01-namespace.yaml
    ```

2. **Deploy and Inspect the Guaranteed Pod:**
    Apply the Guaranteed Pod manifest:

    ```bash
    kubectl apply -f phase-2/day-08/manifests/02-pod-guaranteed.yaml
    ```

    Verify the Pod is running and check its assigned QoS class:

    ```bash
    kubectl get pod guaranteed-pod -n resource-lab -o jsonpath='{.status.qosClass}{"\n"}'
    ```

    *Expected Output:* `Guaranteed`

3. **Deploy and Inspect the Burstable Pod:**
    Apply the Burstable Pod manifest:

    ```bash
    kubectl apply -f phase-2/day-08/manifests/03-pod-burstable.yaml
    ```

    Verify the Pod is running and check its assigned QoS class:

    ```bash
    kubectl get pod burstable-pod -n resource-lab -o jsonpath='{.status.qosClass}{"\n"}'
    ```

    *Expected Output:* `Burstable`

4. **Deploy and Inspect the BestEffort Pod:**
    Apply the BestEffort Pod manifest:

    ```bash
    kubectl apply -f phase-2/day-08/manifests/04-pod-besteffort.yaml
    ```

    Verify the Pod is running and check its assigned QoS class:

    ```bash
    kubectl get pod besteffort-pod -n resource-lab -o jsonpath='{.status.qosClass}{"\n"}'
    ```

    *Expected Output:* `BestEffort`

5. **Simulate and Observe Memory Limit Enforcement (OOMKilled):**
    Apply the OOM test Pod manifest. This pod has a memory limit of `32Mi` but runs an Alpine container executing an `awk` memory allocator script that attempts to allocate approximately `60Mi` of RAM:

    ```bash
    kubectl apply -f phase-2/day-08/manifests/05-pod-oom.yaml
    ```

    Wait a few seconds, then view the status of the Pod:

    ```bash
    kubectl get pods -n resource-lab
    ```

    *Expected Output:* The Pod status should show `OOMKilled` or `CrashLoopBackOff` with restarts.

    Inspect the termination details of the container:

    ```bash
    kubectl describe pod oom-pod -n resource-lab
    ```

    Locate the `Last State` or `State` fields in the output. You should observe:

    ```text
    State:          Terminated
      Reason:       OOMKilled
      Exit Code:    137
    ```

    *Operational Note:* Exit code `137` indicates that the process was terminated by the operating system via a SIGKILL signal due to resource starvation (128 + 9 = 137).

6. **Clean Up:**
    Delete the namespace to remove all workloads:

    ```bash
    kubectl delete namespace resource-lab
    ```

---

[Back to main README.md](../../README.md)
