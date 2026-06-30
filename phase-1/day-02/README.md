# Day 02

This day explores how Pods start, restart, and initialize before app containers run.

## Concept Overview

A Pod is the smallest deployable unit in Kubernetes. It represents a single instance of a running process in your cluster. Understanding the exact sequence of how a Pod starts, runs, and terminates is critical for building resilient applications.

## Core Concepts

### Pod Phases vs. Container States

A Pod has a high-level phase that summarizes its current status. Inside the Pod, individual containers have detailed states.

#### Pod Phases

| Phase | Description |
| --- | --- |
| **Pending** | The Pod has been accepted by the API Server, but one or more containers have not been created or scheduled. This includes time spent waiting to be scheduled as well as downloading images. |
| **Running** | The Pod has been bound to a node, and all containers have been created. At least one container is currently running, or is in the process of starting or restarting. |
| **Succeeded** | All containers in the Pod have terminated successfully (exit code 0) and will not be restarted. |
| **Failed** | All containers in the Pod have terminated, and at least one container has terminated in failure (non-zero exit code). |
| **Unknown** | The state of the Pod cannot be obtained, typically due to a communication failure between the control plane and the kubelet on the worker node. |

#### Container States

A container inside a Pod can be in one of three states:

- **Waiting**: The default state. The container is running initialization work, such as pulling the image or waiting for a secret.
- **Running**: The container is executing without issues.
- **Terminated**: The container completed execution or failed.

### Init Containers

Init containers are specialized containers that run before app containers in a Pod. They are typically used to run initialization scripts, perform database migrations, or wait for dependency services to become ready.

Key characteristics of init containers:

- They always run to completion.
- Each init container must complete successfully before the next one starts.
- If an init container fails, Kubernetes restarts the Pod repeatedly until the init container succeeds (assuming `restartPolicy` is not set to `Never`).
- They do not support lifecycle probes (liveness, readiness, startup).

### Pod Lifecycle Flow

The diagram below outlines the execution sequence from scheduling through init container execution to the main application containers:

```text
Pod scheduled
  ↓
Pending phase
  ↓
Init containers run in order
  ├─ failure + restartPolicy Always/OnFailure → retry init
  ├─ failure + restartPolicy Never → Failed
  └─ success → start app containers
        ↓
      Running phase
        ├─ crash + restartPolicy Always/OnFailure → restart
        ├─ finish successfully + restartPolicy Never → Succeeded
        └─ crash + restartPolicy Never → Failed
```

## Checklist

- [ ] Explain the difference between a Pod Phase and a Container State.
- [ ] Understand the three possible restart policies and when to use each.
- [ ] Describe the execution sequence of init containers.
- [ ] Use kubectl commands to troubleshoot a failing container in a Pod.
- [ ] View and interpret Pod events using `kubectl describe`.

## Lab

In this lab, you will deploy pods with different configurations to observe their states and lifecycles.

### Prerequisites

Ensure your cluster is running and `kubectl` is configured.

### Steps

1. **Deploy a basic application Pod:**
   Apply the basic Pod manifest:

   ```bash
   kubectl apply -f phase-1/day-02/manifests/01-pod-lifecycle.yaml
   ```

   Watch the Pod transition through states:

   ```bash
   kubectl get pods -w
   ```

   Note how the status transitions from `Pending` to `ContainerCreating` and then `Running`.

2. **Inspect Container States:**
   View detailed container states for the running Pod:

   ```bash
   kubectl get pod nginx-lifecycle -o jsonpath='{.status.containerStatuses[0].state}'
   ```

3. **Deploy a Pod with an Init Container:**
   Apply the init container manifest:

   ```bash
   kubectl apply -f phase-1/day-02/manifests/02-init-container.yaml
   ```

   Watch the initialization sequence:

   ```bash
   kubectl get pods -w
   ```

   Notice that the Pod status shows `Init:0/1` during the init container execution, transitions to `PodInitializing`, and finally becomes `Running` when the main application container starts.

4. **Observe Restart Policies in Action:**
   Apply the failing Pod manifest to see restart behavior:

   ```bash
   kubectl apply -f phase-1/day-02/manifests/03-restart-policy.yaml
   ```

   Monitor the restarts:

   ```bash
   kubectl get pods -w
   ```

   Observe the restart count incrementing and the status transitioning into `CrashLoopBackOff` as Kubernetes implements an exponential back-off delay.

5. **Clean Up:**
   Delete all resources created during this lab:

   ```bash
   kubectl delete -f phase-1/day-02/manifests/
   ```

---

[Back to main README.md](../../README.md)
