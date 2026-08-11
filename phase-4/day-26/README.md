# Day 26

This day covers node maintenance, including marking nodes as unschedulable (cordoning), draining workloads, and enforcing Pod Disruption Budgets (PDBs).

## Concept Overview

Before taking a node offline for maintenance (such as OS updates or hardware replacement), you must gracefully move workloads to other active nodes.

```text
[ Active Node ] ──► (kubectl cordon) ──► [ SchedulingDisabled ] (No new pods allowed)
       │
       ▼
(kubectl drain) ──► [ Eviction API checks PDB ] ──► [ Graceful Termination ]
                                                             │
                                                             ▼
                                                    [ Safe to shut down ]
```

---

## Core Concepts

1. **Cordon (`kubectl cordon`):** Marks a node as unschedulable. It prevents new Pods from being scheduled on the node while allowing existing running Pods to continue running. The node receives the status `SchedulingDisabled`.
2. **Uncordon (`kubectl uncordon`):** Re-enables scheduling on a node, allowing new Pods to be placed on it.
3. **Drain (`kubectl drain`):** Combines cordoning with the graceful eviction of all pods running on the node.
4. **Pod Disruption Budget (PDB):** An API object that defines the maximum number of pods that can be voluntarily disrupted (e.g., during a node drain) to guarantee application availability.
5. **Eviction vs Deletion:** Draining uses the Eviction API, which respects PDB constraints. If draining a node would violate a PDB (e.g., dropping active replicas below `minAvailable`), the eviction request is rejected, and the drain command blocks or fails.

---

## Checklist

- [ ] Cordon a node and observe its scheduling status.
- [ ] Deploy a multi-replica application protected by a PodDisruptionBudget.
- [ ] Drain a node and analyze the eviction lifecycle.
- [ ] Understand how a PDB can block or delay a node drain.
- [ ] Restore a node to service by uncordoning it.

---

## Lab

In this lab, you will deploy a high-availability application with a PodDisruptionBudget, cordon a node, and perform a simulated node drain.

### Steps

1. **Create the Lab Namespace and Workloads:**

   Apply the configuration files to deploy the namespace, Nginx deployment, and PodDisruptionBudget:

   ```bash
   kubectl apply -f phase-4/day-26/manifests/01-namespace.yaml
   kubectl apply -f phase-4/day-26/manifests/02-deployment.yaml
   kubectl apply -f phase-4/day-26/manifests/03-pdb.yaml
   ```

2. **Verify Pod Distribution:**

   Check the status of your pods and see which nodes they are scheduled on:

   ```bash
   kubectl get pods -n maintenance-lab -o wide
   ```

3. **Cordon a Node:**

   Choose one node from your cluster (other than your master node if you are on a multi-node cluster, or your single local node for testing). Mark it as unschedulable:

   ```bash
   kubectl cordon <node-name>
   ```

   Check the status of your nodes:

   ```bash
   kubectl get nodes
   ```

   *Expected Outcome:* The target node status will show `Ready,SchedulingDisabled`.

4. **Verify Cordon Blocks Scheduling:**

   Scale the Nginx deployment up to 5 replicas:

   ```bash
   kubectl scale deployment web-ha -n maintenance-lab --replicas=5
   ```

   List the pods again to see where the new replicas are placed:

   ```bash
   kubectl get pods -n maintenance-lab -o wide
   ```

   *Expected Outcome:* None of the new pods will be scheduled on the cordoned node. They will all be scheduled on other active nodes, or remain `Pending` if you only have a single-node cluster.

5. **Drain the Node:**

   Perform a node drain to evict all running workloads:

   ```bash
   kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
   ```

   *Flags Explained:*
   - `--ignore-daemonsets`: DaemonSets run a pod on every node. Because they cannot be rescheduled to other nodes, you must ignore them to drain the node.
   - `--delete-emptydir-data`: Forces eviction of pods using local `emptyDir` storage, which will lose data when deleted.

6. **Inspect PDB Enforcement:**

   Our PDB [03-pdb.yaml](manifests/03-pdb.yaml) specifies `minAvailable: 2`.
   If you have a multi-node cluster and try to drain a node holding multiple replicas of `web-ha`, the eviction API will evict them one at a time, ensuring that at least 2 replicas remain active in the cluster. If you have a single-node cluster, draining the node will fail or hang because evicting the pods would drop active replicas to 0 (violating the PDB).

7. **Restore the Node:**

   Once maintenance is complete, return the node to active scheduling:

   ```bash
   kubectl uncordon <node-name>
   ```

   Verify that the node status returns to `Ready`:

   ```bash
   kubectl get nodes
   ```

8. **Clean Up:**

   ```bash
   kubectl delete namespace maintenance-lab
   ```

---

[Back to main README.md](../../README.md)
