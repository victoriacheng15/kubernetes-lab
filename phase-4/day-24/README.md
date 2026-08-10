# Day 24

This day covers kubeconfig structure, client certificate verification, and cluster credentials inspection.

## Concept Overview

Kubeconfig files configure access to clusters by combining cluster API endpoints, user credentials, and active contexts. Because Kubernetes uses Client Certificates for authentication, checking certificate expiration is vital to cluster operations.

```text
                  [ kubeconfig ]
 ┌──────────────────────┼──────────────────────┐
 │                      │                      │
 ▼                      ▼                      ▼
[ Clusters ]       [ Users ]             [ Contexts ]
 - API Server IP    - Client Certs        - Links Cluster + User
 - CA Certificate   - Auth Tokens         - Default Namespace
```

---

## Core Concepts

1. **Kubeconfig:** A YAML configuration file (typically located at `~/.kube/config`) used to organize cluster access, client identities, and active login profiles.
2. **Context:** A logical linkage in a kubeconfig file that binds a specific user identity to a specific Kubernetes cluster. Setting a context tells `kubectl` where to send requests and which credentials to sign them with.
3. **Control Plane Certificates:** Crucial cluster services (like the API Server, kubelet, and etcd) communicate over mutual TLS (mTLS). These certificates are typically stored on the nodes in `/etc/kubernetes/pki/` or `/var/lib/rancher/k3s/server/tls/` for K3s.
4. **Certificate Expiration:** Kubernetes certificates are standard X.509 certificates and have strict expiration dates (usually 1 year). If a certificate expires, control plane services or users will be blocked from accessing the API.

---

## Checklist

- [ ] Inspect the active kubeconfig structure and parse its contexts.
- [ ] Create and toggle between different mock contexts in `kubectl`.
- [ ] Inspect X.509 client certificate details using `openssl`.
- [ ] Query cluster certificate expiration status using `kubeadm` or direct file inspection.

---

## Lab

In this lab, you will explore the construction of a kubeconfig file, practice context switching, and decode local TLS certificates to check their validation dates.

### Steps

1. **Analyze Kubeconfig Architecture:**

   Open and inspect [01-sample-kubeconfig.yaml](manifests/01-sample-kubeconfig.yaml). Note how the `contexts` section maps the `dev-user` to the `dev-cluster` and automatically sets the default namespace to `dev-namespace`.

2. **Inspect Your Active Kubeconfig:**

   View your local, active kubeconfig settings using `kubectl config view`. This strips out private keys and sensitive token secrets for security:

   ```bash
   kubectl config view
   ```

   To list all available contexts inside your active config:

   ```bash
   kubectl config get-contexts
   ```

   To display the name of the current context in use:

   ```bash
   kubectl config current-context
   ```

3. **Manage Contexts manually:**

   You can create a new context or switch between them directly using `kubectl`:

   ```bash
   # Add a new context pointing to an existing user and cluster
   kubectl config set-context test-context --cluster=local --user=admin --namespace=default

   # Switch your active terminal session to the new context
   kubectl config use-context test-context

   # Verify the switch succeeded
   kubectl config current-context

   # Revert back to your default context (e.g., default)
   kubectl config use-context default
   ```

4. **Verify Certificate Expiration dates:**

   Kubernetes stores CA and client certificates locally on the node.
   - On standard clusters: `/etc/kubernetes/pki/`
   - On K3s clusters: `/var/lib/rancher/k3s/server/tls/`

   You can read any certificate's metadata and verify its expiration date using the `openssl` CLI:

   ```bash
   # Standard kubeadm cert location:
   sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A 2 "Validity"

   # On your local K3s setup:
   sudo openssl x509 -in /var/lib/rancher/k3s/server/tls/client-admin.crt -text -noout | grep -A 2 "Validity"
   ```

   *Expected Outcome:* The output prints the `Not Before` and `Not After` timestamps, indicating when the certificate was issued and when it will expire.

5. **Verify Expirations via Kubeadm:**

   *(For standard clusters initialized via kubeadm, a helper command is available to check all certificate expirations at once):*

   ```bash
   sudo kubeadm certs check-expiration
   ```

6. **Clean Up:**

   If you created the `test-context`, delete it to keep your kubeconfig file tidy:

   ```bash
   # Ensure you are on your default context first
   kubectl config use-context default

   # Delete the temporary test context
   kubectl config delete-context test-context
   ```

---

[Back to main README.md](../../README.md)
