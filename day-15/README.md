# Day 15

This day covers RBAC objects and how ServiceAccounts, Roles, and Bindings control API access.

## Concept Overview

Kubernetes RBAC controls **who** can do **what** in the cluster. Workloads use **ServiceAccounts** as their identity, while **Roles** and **ClusterRoles** define allowed actions. **RoleBindings** and **ClusterRoleBindings** attach those permissions to users, groups, or ServiceAccounts.

```text
                 [ Kubernetes API Server ]
                           ▲
                           │
             authz check   │   authz check
                           │
        ┌──────────────────┴──────────────────┐
        │                                     │
[ RoleBinding ]                       [ ClusterRoleBinding ]
        │                                     │
[ Role: pod-reader ]               [ ClusterRole: node-reader ]
        │                                     │
[ ServiceAccount: rbac-tester ]  [ ServiceAccount: rbac-tester ]
        │                                     │
        └───────────────[ rbac-debugger Pod ]─┘
```

---

## Core Concepts

1. **ServiceAccount:** A namespace-scoped identity used by Pods when talking to the API server.
2. **Role:** Namespace-scoped permissions for resources in a single namespace.
3. **ClusterRole:** Cluster-scoped permissions that can apply across namespaces or to cluster resources.
4. **RoleBinding / ClusterRoleBinding:** Attach a Role or ClusterRole to a subject such as a ServiceAccount.

---

## Checklist

- [ ] Create a dedicated namespace for the RBAC lab.
- [ ] Create a ServiceAccount for the test workload.
- [ ] Grant namespace-scoped read access with a Role and RoleBinding.
- [ ] Grant cluster-scoped read access with a ClusterRole and ClusterRoleBinding.
- [ ] Deploy a Pod that uses the ServiceAccount.
- [ ] Validate permissions with `kubectl auth can-i`.

---

## Lab

In this lab, you will create a ServiceAccount, bind it to namespace-scoped and cluster-scoped read permissions, and verify the resulting access with `kubectl auth can-i`.

### Steps

1. **Create the Namespace:**

   ```bash
   kubectl apply -f day-15/manifests/01-namespace.yaml
   ```

2. **Create the ServiceAccount and RBAC Rules:**

   ```bash
   kubectl apply -f day-15/manifests/02-serviceaccount.yaml
   kubectl apply -f day-15/manifests/03-role.yaml
   kubectl apply -f day-15/manifests/04-rolebinding.yaml
   kubectl apply -f day-15/manifests/05-clusterrole.yaml
   kubectl apply -f day-15/manifests/06-clusterrolebinding.yaml
   ```

3. **Deploy the Test Pod:**

   ```bash
   kubectl apply -f day-15/manifests/07-debug-pod.yaml
   kubectl get pod -n rbac-lab
   ```

4. **Verify Namespace-Scoped Access:**

   ```bash
   kubectl auth can-i list pods --as=system:serviceaccount:rbac-lab:rbac-tester -n rbac-lab
   kubectl auth can-i get configmaps --as=system:serviceaccount:rbac-lab:rbac-tester -n rbac-lab
   kubectl auth can-i create deployments --as=system:serviceaccount:rbac-lab:rbac-tester -n rbac-lab
   ```

   *Expected Outcome:* The first two commands should return `yes`, and the last command should return `no`.

5. **Verify Cluster-Scoped Access:**

   ```bash
   kubectl auth can-i list nodes --as=system:serviceaccount:rbac-lab:rbac-tester
   ```

   *Expected Outcome:* This should return `yes` because the ServiceAccount is bound to a ClusterRole.

6. **Inspect the Pod Identity:**

   ```bash
   kubectl exec -n rbac-lab rbac-debugger -- cat /var/run/secrets/kubernetes.io/serviceaccount/namespace
   ```

   *Expected Outcome:* The Pod should report `rbac-lab`, confirming it is running with the expected ServiceAccount identity.

7. **Clean Up:**

   ```bash
   kubectl delete clusterrolebinding node-reader-binding
   kubectl delete clusterrole node-reader
   kubectl delete namespace rbac-lab
   ```

---

[Back to main README.md](../README.md)
