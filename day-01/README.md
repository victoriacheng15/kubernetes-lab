# Day 01

Kubernetes is a container orchestration system that manages workloads across a cluster of machines. This lab introduces the control plane, worker nodes, and the basic request flow that keeps a cluster aligned with desired state.

## Concept Overview

Kubernetes cluster architecture is built around two main areas: the control plane, which makes decisions, and worker nodes, which run workloads.

## Core Concepts

| Area | Control Plane | Worker Node |
| --- | --- | --- |
| Main role | Manages cluster state and decisions | Runs application workloads |
| Key components | API Server, etcd, Scheduler, Controller Manager | Kubelet, kube-proxy, container runtime, CNI |
| Stores cluster state? | Yes, through etcd | No |
| Runs Pods? | Usually system Pods; may run workloads depending on cluster setup | Yes |
| Failure impact | Can affect scheduling and cluster management | Can affect workloads on that node |

- Control plane: Accepts requests, stores cluster state, schedules workloads, and reconciles desired state.
- Worker nodes: Run Pods, connect workloads to the network, and report status back to the control plane.
- Desired state: The configuration you ask Kubernetes to maintain.
- Reconciliation: The process Kubernetes uses to compare current state with desired state and take action.

### Notes

- A Kubernetes node does not always mean a separate physical machine. In local clusters, multiple nodes can run on one machine as VMs or containers.

- API Server: The front door to Kubernetes. All requests go through it.
- etcd: The key-value store that holds cluster state.
- Scheduler: Chooses which node should run a new Pod.
- Controller Manager: Runs controllers that keep the cluster moving toward desired state.
- Kubelet: Runs on each node and makes sure assigned Pods are running.
- kube-proxy: Handles Service networking rules on nodes.
- Container runtime: Starts and manages containers.
- CNI: Provides Pod networking.

Kubernetes follows a control loop when a workload is created:

```text
User
  |
  v
API Server -> etcd
      |
      v
  Scheduler
      |
      v
    Kubelet -> Container Runtime -> Running Pod
```

## Checklist

- [ ] Identify the cluster nodes and their roles.
- [ ] Locate the system namespaces.
- [ ] Find the core Kubernetes Pods.
- [ ] Explain the role of the API Server, etcd, Scheduler, Controller Manager, Kubelet, kube-proxy, container runtime, and CNI.
- [ ] Describe the request flow from workload creation to a running Pod.

## Lab

Day 01 is about understanding what already exists, so this lab focuses on observing the cluster instead of creating new workloads.

### Steps

- List all nodes and identify control plane and worker nodes: `kubectl get nodes -o wide`
- Inspect all namespaces: `kubectl get namespaces`
- Inspect system Pods: `kubectl get pods -n kube-system -o wide`
- Inspect cluster info: `kubectl cluster-info`
- Describe one node and note its conditions: `kubectl describe node <node-name>`
- Describe one system Pod and explain what it does: `kubectl describe pod <pod-name> -n kube-system`
- Clean up: no resources were created, so nothing needs to be deleted.

---

[Back to main README.md](../README.md)
