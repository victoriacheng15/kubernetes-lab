# Day 10

## Scheduling Control: Taints and Tolerations

While node affinity (Day 09) allows a Pod to actively *choose* which nodes it wants to schedule on, **taints and tolerations** work in the opposite direction. They allow a Node to **repel** a set of Pods. 

A taint is applied to a node to signify that it should only accept specific workloads. A toleration is applied to a Pod to allow (but not force) it to be scheduled on a tainted node.

```text
           [ Pod Created ]
                  │
                  ▼
        ┌───────────────────┐
        │ Target Node has   │
        │ Taint applied?    │───No───► [ Schedules Normally ]
        └───────────────────┘
                  │
                 Yes (e.g., dedicated=database:NoSchedule)
                  │
                  ▼
        ┌───────────────────┐
        │ Pod has matching  │
        │ Toleration?       │───No───► [ Repelled / Pending ]
        └───────────────────┘
                  │
                 Yes (e.g., tolerates dedicated=database)
                  │
                  ▼
       [ Scheduled on Node ]
```

---

## Taint Effects

When you apply a taint to a node, you must define its **effect**. Kubernetes support three taint effects:

| Taint Effect | Behavior |
| :--- | :--- |
| **NoSchedule** | Hard constraint. If a Pod does not have a matching toleration, it will not be scheduled on the node. Existing running pods on the node are unaffected. |
| **PreferNoSchedule** | Soft constraint. The control plane will try to avoid scheduling the Pod on the tainted node, but will place it there if no other compute resources are available. |
| **NoExecute** | Eviction constraint. If a taint with this effect is added to a node, any running Pod that does not tolerate it is immediately evicted (killed) from the node. |

---

## Practical Use Cases

Taints and tolerations are critical for cluster administration in multi-tenant environments:
1.  **Dedicated Nodes:** Reserving specific nodes for databases, machine learning GPU workloads, or licensed software. By tainting the nodes, you prevent standard application pods from occupying them.
2.  **Node Drain and Maintenance:** When cordoning or draining a node for upgrades, the system automatically applies taints to repel new pods.
3.  **Handling Node Outages:** The control plane automatically applies taints like `node.kubernetes.io/unreachable:NoExecute` or `node.kubernetes.io/not-ready:NoExecute` to bad nodes. Any pod running on them that does not tolerate these taints will be evicted and rescheduled on healthy nodes.

---

## Checklist

- [ ] Apply and remove a taint on a cluster node using `kubectl`.
- [ ] Deploy an un-tolerated Pod and observe how the node taint repels it.
- [ ] Deploy a tolerated Pod and verify it can successfully schedule on the tainted node.
- [ ] Understand the difference between `NoSchedule` and `NoExecute` effects.

---

## Lab: Enforcing Workload Isolation via Taints

In this lab, you will taint a local node to act as a dedicated database server, observe how it repels standard workloads, and deploy a pod with matching tolerations.

### Steps

1.  **Create the Namespace:**
    Apply the namespace manifest:
    ```bash
    kubectl apply -f day-10/manifests/01-namespace.yaml
    ```

2.  **Inspect and Taint your Node:**
    Identify a target node name:
    ```bash
    kubectl get nodes
    ```
    Apply a taint to the node. This taint specifies that the node is dedicated to databases and has a hard `NoSchedule` effect (replace `<node-name>` with your node name):
    ```bash
    kubectl taint nodes <node-name> dedicated=database:NoSchedule
    ```
    Verify the taint is active:
    ```bash
    kubectl describe node <node-name> | grep Taints
    ```

3.  **Deploy a Pod without Tolerations:**
    Apply the standard web server Pod manifest, which lacks any tolerations:
    ```bash
    kubectl apply -f day-10/manifests/02-pod-un-tolerated.yaml
    ```
    Check the status of the Pod:
    ```bash
    kubectl get pods -n tolerations-lab
    ```
    *Expected Outcome:* The Pod will remain in a `Pending` state.
    
    Describe the Pod to verify it was repelled by the node taint:
    ```bash
    kubectl describe pod untolerated-pod -n tolerations-lab
    ```
    *Expected Event:* You should see a warning event: `FailedScheduling` with the message: `1 node(s) had untolerated taint {dedicated: database}`.

4.  **Deploy a Pod with Matching Tolerations:**
    Apply the database Pod manifest, which carries a matching toleration:
    ```bash
    kubectl apply -f day-10/manifests/03-pod-tolerated.yaml
    ```
    Verify that this database Pod successfully bypasses the taint and runs:
    ```bash
    kubectl get pods -n tolerations-lab
    ```
    *Expected Outcome:* The database Pod will transition to `Running`, while the web Pod remains `Pending`.

5.  **Clean Up:**
    Remove the taint from the node by suffixing the taint key and effect with a minus sign `-`:
    ```bash
    kubectl taint nodes <node-name> dedicated=database:NoSchedule-
    ```
    Verify that the untolerated web Pod now automatically schedules and starts running once the node is untainted. Then, delete the namespace:
    ```bash
    kubectl delete namespace tolerations-lab
    ```

---

[Back to main README.md](../README.md)
