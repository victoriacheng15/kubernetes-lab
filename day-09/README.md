# Day 09

This day covers pod scheduling controls such as node selectors, affinity, and anti-affinity.

## Concept Overview

In a standard Kubernetes cluster, the default scheduler automatically places Pods on nodes with the most available resources. However, real-world production systems require direct control over workload placement for several reasons:

1. **Hardware Requirements:** Matching intensive database workloads to nodes equipped with SSDs, high memory, or GPU accelerators.
2. **High Availability (HA):** Spreading replicas of a critical microservice across different physical racks or availability zones to prevent single-point failures.
3. **Data Locality:** Co-locating helper services (like an application container and its local cache) on the same node or in the same zone to minimize network latency.

Kubernetes provides three main mechanisms to control scheduling topology:

```text
                     [ Pod Scheduling Decision ]
                                  │
         ┌────────────────────────┴────────────────────────┐
         ▼                                                 ▼
  Node-Centric Rules                                Pod-Centric Rules
 (Schedule based on Node labels)                   (Schedule based on running Pods)
         │                                                 │
   ┌─────┴─────┐                                     ┌─────┴─────┐
   ▼           ▼                                     ▼           ▼
nodeSelector  nodeAffinity                        podAffinity  podAntiAffinity
(Simple KV)   (Expressive, hard/soft rules)       (Co-locate)  (Distribute for HA)
```

---

## Core Concepts

### Comparison Matrix

| Mechanism | Rule Type | Operators | Flexibility | Common Use Case |
| :--- | :--- | :--- | :--- | :--- |
| **nodeSelector** | Node-centric (Hard) | Equality (`=`) | Low | Directing pods to nodes with specific storage or hardware (e.g., `disktype: ssd`). |
| **nodeAffinity** | Node-centric (Hard/Soft) | `In`, `NotIn`, `Exists`, `DoesNotExist`, `Gt`, `Lt` | High | Restricting workloads to specific zones (e.g., `us-east-1a`) or preferring (but not requiring) high-memory hosts. |
| **podAffinity** | Pod-centric (Hard/Soft) | `In`, `NotIn`, `Exists`, `DoesNotExist` | High | Placing a web application container on the same host node as its cache helper container. |
| **podAntiAffinity** | Pod-centric (Hard/Soft) | `In`, `NotIn`, `Exists`, `DoesNotExist` | High | Ensuring multiple replicas of a frontend pod are never scheduled on the same physical node. |

---

### Hard vs. Soft Constraints

For affinity and anti-affinity rules, you must choose between hard and soft execution:

* **Hard Constraint (`requiredDuringSchedulingIgnoredDuringExecution`):** The scheduler **must** find a node that meets the rule. If no node matches, the Pod will remain in a `Pending` state indefinitely.
* **Soft Constraint (`preferredDuringSchedulingIgnoredDuringExecution`):** The scheduler will attempt to find a node that meets the rule. If no matching node is available, the scheduler will ignore the preference and schedule the Pod on any healthy node.

---

## Checklist

* [ ] Label and un-label cluster nodes using `kubectl`.
* [ ] Deploy a Pod using `nodeSelector` and observe its scheduling behavior.
* [ ] Deploy a Pod using hard `nodeAffinity` constraints.
* [ ] Deploy Pods using `podAffinity` to co-locate workloads.
* [ ] Deploy Pods using `podAntiAffinity` to enforce high availability distribution.

---

## Lab

In this lab, you will label your local nodes, deploy scheduling constraints, and observe how the Kubernetes scheduler responds when rules cannot be satisfied.

### Steps

1. **Create the Namespace:**
    Apply the namespace manifest:

    ```bash
    kubectl apply -f day-09/manifests/01-namespace.yaml
    ```

2. **Inspect Nodes and Apply Labels:**
    List the nodes in your cluster:

    ```bash
    kubectl get nodes
    ```

    Choose one node and apply a custom storage label to it (replace `<node-name>` with your actual node name, such as `minikube` or `kind-control-plane`):

    ```bash
    kubectl label nodes <node-name> disktype=ssd
    ```

    Verify that the label has been applied successfully:

    ```bash
    kubectl get nodes --show-labels
    ```

3. **Deploy the NodeSelector Pod:**
    Apply the NodeSelector Pod manifest. This pod requires a node labeled with `disktype=ssd`:

    ```bash
    kubectl apply -f day-09/manifests/02-pod-nodeselector.yaml
    ```

    Verify the Pod is running:

    ```bash
    kubectl get pods -n scheduling-lab
    ```

    *Note:* If you did not label your node correctly, the Pod will remain in a `Pending` state. You can verify this by describing the Pod:

    ```bash
    kubectl describe pod nodeselector-pod -n scheduling-lab
    ```

4. **Deploy the NodeAffinity Pod:**
    Apply the NodeAffinity Pod manifest, which utilizes a hard scheduling constraint requiring the node to be in zone `us-east-1a` or `us-east-1b`:

    ```bash
    kubectl apply -f day-09/manifests/03-pod-nodeaffinity.yaml
    ```

    View the Pod status:

    ```bash
    kubectl get pods -n scheduling-lab -l app=affinity-test
    ```

    *Expected Outcome:* Because none of your local nodes have the label `topology.kubernetes.io/zone=us-east-1a` or `us-east-1b`, the Pod will remain `Pending`.

    Label one of your nodes to satisfy this constraint:

    ```bash
    kubectl label nodes <node-name> topology.kubernetes.io/zone=us-east-1a
    ```

    Verify the scheduler immediately detects the change and transitions the Pod to `Running`:

    ```bash
    kubectl get pods -n scheduling-lab -l app=affinity-test
    ```

5. **Deploy PodAffinity (Co-location):**
    First, deploy the core database Pod:

    ```bash
    kubectl apply -f day-09/manifests/04-pod-db.yaml
    ```

    Wait for the database Pod to be scheduled and running. Then, deploy the web client Pod, which has a hard `podAffinity` rule requiring it to run on the same node (topology domain `kubernetes.io/hostname`) as any pod with the label `app=database`:

    ```bash
    kubectl apply -f day-09/manifests/05-pod-podaffinity.yaml
    ```

    Verify that the client pod is running on the exact same node as the database pod:

    ```bash
    kubectl get pods -n scheduling-lab -o wide
    ```

6. **Deploy PodAntiAffinity (HA Distribution):**
    Apply the anti-affinity manifest. This deploys a web server Pod configured with `podAntiAffinity` to prevent multiple replicas from running on the same node:

    ```bash
    kubectl apply -f day-09/manifests/06-pod-podantiaffinity.yaml
    ```

    *Note for single-node clusters:* If you are running a single-node local cluster (like minikube), only the first pod will run. The second pod will remain `Pending` because it cannot find another node to run on without violating the anti-affinity rule. This demonstrates how Kubernetes enforces high availability at the cost of scheduling flexibility.

7. **Clean Up:**
    Remove the namespace and clean up the node labels:

    ```bash
    kubectl delete namespace scheduling-lab
    kubectl label nodes <node-name> disktype-
    kubectl label nodes <node-name> topology.kubernetes.io/zone-
    ```

    *(Note: Appending a minus sign `-` to a label key removes that label from the node)*

---

[Back to main README.md](../README.md)
