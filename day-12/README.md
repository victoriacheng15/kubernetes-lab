# Day 12

This day covers NetworkPolicies and how they restrict ingress and egress traffic between pods.

## Concept Overview

By default, Kubernetes networking is flat and non-isolated. Any Pod in any namespace can communicate with any other Pod in the cluster. While this simplifies service discovery, it violates the security principle of **least privilege**. If a public-facing web server is compromised, an attacker can freely scan and connect to internal database pods or system management APIs.

To secure cluster communication, Kubernetes uses **NetworkPolicies**, which act as namespace-scoped firewalls for Pods.

```text
  [ frontend-pod ] (app=frontend)
        │
        │ (Allowed on port 6379)
        ▼
  [ db-pod ] (app=database)  ◄───[ NetworkPolicy: secure-db ]
        ▲
        │ (Blocked by default isolation)
        │
  [ unauthorized-pod ] (app=unauthorized)
```

---

## Core Concepts

* **Default Non-Isolation:** By default, all Pods are un-isolated (all traffic is allowed).
* **Isolation Rule:** Once a NetworkPolicy selects a Pod (using `podSelector`), that Pod becomes **isolated** for that specific policy type. Any incoming (Ingress) or outgoing (Egress) traffic is blocked unless it matches an explicit allow rule.
* **Policy Types:**
  * **Ingress:** Restricts incoming traffic based on source (from `podSelector`, `namespaceSelector`, or `ipBlock`) and target port.
  * **Egress:** Restricts outgoing traffic based on destination (to `podSelector`, `namespaceSelector`, or `ipBlock`) and target port.
* **CNI Requirement:** NetworkPolicies are not enforced by the control plane directly. They require a Container Network Interface (CNI) plugin that supports policy enforcement (such as Cilium, Calico, or Kube-Router). If using a basic CNI like Flannel, NetworkPolicies are silently ignored.

---

### NetworkPolicy Selector Logic

When writing rules, you specify who can connect to the target Pod:

1. **podSelector:** Selects pods within the **same** namespace.
2. **namespaceSelector:** Selects pods running in **different** namespaces that carry specific namespace labels.
3. **ipBlock:** Restricts traffic to or from specific IP ranges (CIDR blocks), commonly used for external database servers or external APIs outside the cluster.

---

## Checklist

* [ ] Verify if the cluster's CNI supports NetworkPolicies.
* [ ] Deploy an isolated backend database Pod and a client Pod.
* [ ] Implement a default-deny NetworkPolicy to isolate the database.
* [ ] Create an ingress allow rule permitting traffic only from a labeled frontend Pod.
* [ ] Validate traffic blocking from an unauthorized Pod.

---

## Lab

In this lab, you will deploy a Redis database Pod, isolate it using a NetworkPolicy, and demonstrate how the policy blocks unauthorized traffic while allowing traffic from a verified frontend Pod.

### Steps

1. **Create the Namespace:**
    Apply the namespace manifest:

    ```bash
    kubectl apply -f day-12/manifests/01-namespace.yaml
    ```

2. **Deploy the Workloads:**
    Apply the database, authorized frontend, and unauthorized client Pods:

    ```bash
    kubectl apply -f day-12/manifests/02-pod-db.yaml
    kubectl apply -f day-12/manifests/03-pod-frontend.yaml
    kubectl apply -f day-12/manifests/04-pod-unauthorized.yaml
    ```

    Verify they are all running:

    ```bash
    kubectl get pods -n network-lab -o wide
    ```

3. **Verify Default Connectivity:**
    Test network connectivity from both client pods to the database before applying any firewall policies.
    * **From Frontend Pod:**

        ```bash
        kubectl exec frontend-pod -n network-lab -- nc -zv db-service 6379
        ```

    * **From Unauthorized Pod:**

        ```bash
        kubectl exec unauthorized-pod -n network-lab -- nc -zv db-service 6379
        ```

    * *Expected Outcome:* Both connections should succeed, outputting: `db-service (10.x.x.x:6379) open`.

4. **Isolate the Database (Apply NetworkPolicy):**
    Apply the NetworkPolicy manifest. This policy selects the database Pod (`app: database`) and defines an Ingress rule that only allows traffic from pods carrying the label `app: frontend` on port `6379`:

    ```bash
    kubectl apply -f day-12/manifests/05-policy-secure-db.yaml
    ```

    Verify the policy is active in the namespace:

    ```bash
    kubectl get networkpolicies -n network-lab
    ```

5. **Validate Policy Enforcement:**
    *(Note: This step requires a CNI like Calico or Cilium active in your cluster. If using a CNI without policy support, both connections will continue to succeed).*

    * **Test Authorized Connection:**

        ```bash
        kubectl exec frontend-pod -n network-lab -- nc -zv db-service 6379
        ```

        *Expected Outcome:* The connection succeeds (`open`) because the pod selector matches the allow rule.
    * **Test Blocked Connection:**

        ```bash
        kubectl exec unauthorized-pod -n network-lab -- nc -zv -w 5 db-service 6379
        ```

        *Expected Outcome:* The connection will timeout (or fail with connection refused) because the pod does not carry the `app: frontend` label and is blocked by the default deny rule.

6. **Clean Up:**
    Delete the namespace to remove all workloads and policies:

    ```bash
    kubectl delete namespace network-lab
    ```

---

[Back to main README.md](../README.md)
