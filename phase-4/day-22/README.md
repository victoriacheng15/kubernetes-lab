# Day 22

This day covers cluster bootstrapping using `kubeadm`, including the control plane initialization and worker node join workflow.

## Concept Overview

Kubernetes cluster setup via `kubeadm` orchestrates the creation of the control plane components on the master node and uses secure TLS bootstrapping to join worker nodes.

```text
[ control-plane node ] (kubeadm init)
         │
         ├──► Generates Bootstrap Token ("abcdef.0123456789abcdef")
         │
         ▼
[ worker node ] ──► (kubeadm join --token ...) ──► [ Requests Certificate (CSR) ]
                                                              │
                                                              ▼ (Auto-Approved)
                                                   [ Node Joins Cluster ]
```

---

## Core Concepts

1. **kubeadm init:** Initializes the Kubernetes control plane. It generates certificates, creates kubeconfig files, starts static pods for control plane services (API Server, Controller Manager, Scheduler), and generates a bootstrap token.
2. **kubeadm join:** Connects a worker node to the cluster. The node uses the bootstrap token to authenticate with the API server and request its local certificates.
3. **Bootstrap Token:** A short-lived credential used for mutual authentication between joining nodes and the control plane. It is stored as a Secret in the `kube-system` namespace.
4. **TLS Bootstrapping:** The process where a new node requests a client certificate from the cluster's CA (via a CertificateSigningRequest). The cluster automatically approves CSRs for node credentials.

---

## Checklist

- [ ] Inspect a sample `kubeadm` configuration file.
- [ ] Create and inspect a custom Bootstrap Token Secret.
- [ ] List, create, and manage bootstrap tokens using `kubeadm token` commands.
- [ ] Inspect the CertificateSigningRequest (CSR) approval process.

---

## Lab

In this lab, you will explore the kubeadm configuration schema, create a mock Bootstrap Token, and practice managing bootstrap tokens.

### Steps

1. **Inspect the Kubeadm Configuration:**

   Open and inspect [01-kubeadm-config.yaml](manifests/01-kubeadm-config.yaml). This file configures the cluster settings (such as subnet sizes and Kubernetes versions) before initializing a cluster.

2. **Deploy the Mock Bootstrap Token:**

   Apply the Secret manifest to create a valid bootstrap token in the cluster:

   ```bash
   kubectl apply -f phase-4/day-22/manifests/02-bootstrap-token.yaml
   ```

3. **Verify the Token Secret:**

   List the bootstrap token secrets in the `kube-system` namespace:

   ```bash
   kubectl get secrets -n kube-system | grep bootstrap-token
   ```

   Describe the token secret:

   ```bash
   kubectl describe secret bootstrap-token-abcdef -n kube-system
   ```

   *Expected Outcome:* You should see the keys `token-id`, `token-secret`, and usage permissions. When K3s or standard Kubernetes reads this secret, it registers `abcdef.0123456789abcdef` as a valid token for joining nodes.

4. **Manage Tokens with Kubeadm:**

   *(Note: This step requires a cluster running upstream Kubernetes where the `kubeadm` binary is installed. On your local K3s setup, these commands are for reference, as K3s manages node registration internally).*

   To list all active tokens:

   ```bash
   kubeadm token list
   ```

   To generate a new join token (default expiration is 24 hours):

   ```bash
   kubeadm token create
   ```

   To generate a token and print the full `kubeadm join` command (including the CA certificate hash):

   ```bash
   kubeadm token create --print-join-command
   ```

5. **Clean Up:**

   Delete the mock token:

   ```bash
   kubectl delete secret bootstrap-token-abcdef -n kube-system
   ```

---

[Back to main README.md](../../README.md)
