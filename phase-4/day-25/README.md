# Day 25

This day covers Kubernetes cluster upgrade workflows and control plane version skew compatibility rules.

## Concept Overview

Upgrading a Kubernetes cluster using `kubeadm` is performed in a precise, rolling sequence to maintain cluster availability. Additionally, Kubernetes enforces strict version compatibility rules (version skew) between the control plane and node components.

```text
[ Current: v1.34.0 ] ──► (Upgrade kubeadm) ──► (kubeadm upgrade plan)
                                                       │
                                                       ▼
[ Upgrade Control Plane ] ──► (kubeadm upgrade apply v1.35.0) ──► [ Upgrade Kubelet/Kubectl ]
                                                                             │
                                                                             ▼
[ Upgrade Worker Nodes ] ◄─── (kubeadm upgrade node) ◄─── (Drain & Upgrade Kubelet)
```

---

## Core Concepts

1. **Version Skew Policy:** The rules governing the maximum allowable difference in minor versions between components:
   * **kube-apiserver:** The cluster core. All other components are compared against its version.
   * **kube-controller-manager & kube-scheduler:** Must be at most **1 minor version older** than `kube-apiserver`.
   * **kubelet (Nodes):** Must be at most **3 minor versions older** than `kube-apiserver` (as of v1.28). They can never be newer.
   * **kubectl (Client):** Must be within **1 minor version** (+/- 1) of `kube-apiserver`.
2. **Kubeadm Upgrade Sequence:** Control plane components are upgraded first, followed by control plane kubelets, and finally worker nodes.
3. **Upgrade Command Flow:**
   * `kubeadm upgrade plan`: Checks for available updates and verifies component compatibility.
   * `kubeadm upgrade apply`: Upgrades control plane static pod manifests and etcd config.
   * `kubeadm upgrade node`: Upgrades local configurations on additional control plane or worker nodes.

---

## Checklist

* [ ] Study the component version skew compatibility matrix.
* [ ] Inspect a sample kubelet configuration file.
* [ ] Review the step-by-step control plane upgrade process.
* [ ] Review the step-by-step worker node upgrade process.

---

## Lab

In this lab, you will study the kubeadm upgrade command structure and learn how to check version compatibility in a running cluster.

### Steps

1. **Verify Current Component Versions:**

   Query your running cluster to check the active version of all control plane and node components:

   ```bash
   kubectl get nodes
   ```

   To inspect the detailed versions of the control plane images running on the nodes:

   ```bash
   kubectl get pods -n kube-system -l tier=control-plane -o wide
   ```

2. **Simulate a Kubeadm Upgrade Plan:**

   *(Note: This step requires a node initialized with kubeadm. On local K3s environments, upgrades are managed by replacing the K3s binary or using the K3s System Upgrade Controller).*

   To run an upgrade check on a control-plane node:

   ```bash
   # 1. Update your package manager repository index
   # 2. Upgrade the kubeadm binary (example for Debian/Ubuntu)
   sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubeadm=1.35.0-1.1

   # 3. Plan the upgrade to see compatibility alerts
   sudo kubeadm upgrade plan
   ```

   *Expected Outcome:* The tool checks external registries and outputs a table listing component current versions, proposed upgrade versions, and whether manual changes are needed.

3. **Execute Control Plane Upgrade:**

   Apply the upgrade configuration to the API server, controller manager, scheduler, and etcd static pods:

   ```bash
   sudo kubeadm upgrade apply v1.35.0
   ```

4. **Upgrade Control Plane Kubelet:**

   Once the static pod manifests are updated, upgrade the host's kubelet service:

   ```bash
   # Drain the control plane node to evict non-essential workloads
   kubectl drain <control-plane-node-name> --ignore-daemonsets --delete-emptydir-data

   # Upgrade kubelet and kubectl packages
   sudo apt-get install -y --allow-change-held-packages kubelet=1.35.0-1.1 kubectl=1.35.0-1.1

   # Restart the kubelet service
   sudo systemctl daemon-reload
   sudo systemctl restart kubelet

   # Uncordon the node to resume scheduling
   kubectl uncordon <control-plane-node-name>
   ```

5. **Upgrade Worker Nodes:**

   For each worker node in the cluster, run the node upgrade sequence:

   ```bash
   # 1. From the control plane node, drain the worker node:
   kubectl drain <worker-node-name> --ignore-daemonsets --delete-emptydir-data

   # 2. On the worker node, upgrade kubeadm and run local node upgrade:
   sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubeadm=1.35.0-1.1
   sudo kubeadm upgrade node

   # 3. On the worker node, upgrade kubelet and kubectl, then restart:
   sudo apt-get install -y --allow-change-held-packages kubelet=1.35.0-1.1 kubectl=1.35.0-1.1
   sudo systemctl daemon-reload
   sudo systemctl restart kubelet

   # 4. From the control plane node, uncordon the worker node:
   kubectl uncordon <worker-node-name>
   ```

---

[Back to main README.md](../../README.md)
