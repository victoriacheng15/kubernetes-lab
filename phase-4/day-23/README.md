# Day 23

This day covers static pods, control plane manifests, and how to inspect cluster control plane components.

## Concept Overview

Static Pods are managed directly by the local `kubelet` daemon on a node, bypassing the control plane API server. They are defined by placing raw YAML files in a designated local directory on the node.

```text
[ /etc/kubernetes/manifests/ ]  ◄─── (Local Directory)
               │
               ▼
        [ kubelet ]  ──► (Manages local containers)
               │
               ▼ (Creates a "Mirror Pod")
     [ API Server ]  ◄─── (Visible via 'kubectl get pods')
```

---

## Core Concepts

1. **Static Pods:** Pods configured via local files on the node. The local `kubelet` monitors the directory and automatically creates, restarts, or deletes the Pods as files are modified or removed.
2. **Mirror Pods:** For every static pod, the local kubelet tells the API server to create a read-only "mirror pod" so that cluster administrators can observe its health using standard `kubectl` commands. You cannot edit, delete, or scale static pods via `kubectl`.
3. **Control Plane Manifests:** In clusters provisioned by `kubeadm`, the core services (`kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, and `etcd`) are run as static pods. Their configurations reside in `/etc/kubernetes/manifests/`.
4. **Static Pod Path Configuration:** The path watched by the kubelet is defined in the kubelet's configuration file (usually `/var/lib/kubelet/config.yaml`) under the `staticPodPath` field.

---

## Checklist

- [ ] Identify where static pod configurations are located.
- [ ] Inspect existing control plane static pods in a standard cluster.
- [ ] Deploy a custom static pod on a node.
- [ ] Observe the mirror pod creation in the API server.
- [ ] Verify that static pods cannot be deleted via the API server.

---

## Lab

In this lab, you will learn how to configure the kubelet to watch a static pod directory and inspect the lifecycle of a static pod.

### Steps

1. **Locate Kubelet Configuration:**

   On a standard Kubernetes node, the kubelet configuration file is located at `/var/lib/kubelet/config.yaml`. Inside this file, look for the `staticPodPath` setting:

   ```bash
   # On a control plane node:
   grep staticPodPath /var/lib/kubelet/config.yaml
   ```

   *Expected Output:*
   `staticPodPath: /etc/kubernetes/manifests`

2. **Inspect Control Plane Static Pods:**

   List the static pod manifests that power your control plane:

   ```bash
   # On a control plane node:
   ls -la /etc/kubernetes/manifests/
   ```

   *Expected Output:*
   - `etcd.yaml`
   - `kube-apiserver.yaml`
   - `kube-controller-manager.yaml`
   - `kube-scheduler.yaml`

3. **Deploy a Custom Static Pod:**

   To simulate a static pod launch:
   1. Copy the sample manifest [01-static-web.yaml](manifests/01-static-web.yaml) to the kubelet's static pod directory.
   2. *(Note: On your local K3s setup, K3s does not use `/etc/kubernetes/manifests` by default, but you can configure the kubelet to watch a directory or inspect existing mirror pods in the `kube-system` namespace).*

   If you have a standard kubelet running:

   ```bash
   sudo cp phase-4/day-23/manifests/01-static-web.yaml /etc/kubernetes/manifests/
   ```

4. **Verify Mirror Pod Creation:**

   After copying the file, wait a few seconds and run:

   ```bash
   kubectl get pods -A
   ```

   *Expected Outcome:* You will see a pod named `static-web-<node-name>`. The node name suffix is automatically appended by the kubelet to distinguish static pods from API-managed pods.

5. **Attempt API-Based Deletion:**

   Try to delete the pod using `kubectl`:

   ```bash
   kubectl delete pod static-web-<node-name>
   ```

   *Expected Outcome:* The API server responds that the pod is deleted, but if you run `kubectl get pods` again immediately, the pod is still running. This is because the kubelet on the node noticed the pod was missing and immediately recreated it from the local file.

6. **Clean Up:**

   To delete the static pod permanently, you must remove the file from the node's local directory:

   ```bash
   sudo rm /etc/kubernetes/manifests/01-static-web.yaml
   ```

   Verify that the mirror pod has disappeared:

   ```bash
   kubectl get pods
   ```

---

[Back to main README.md](../../README.md)
