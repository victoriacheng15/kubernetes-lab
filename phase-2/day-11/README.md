# Day 11

This day covers persistent storage primitives and how PVCs bind to PVs and StorageClasses.

## Concept Overview

By default, container filesystems are ephemeral. If a container crashes or restarts, any files written inside it are lost, and the container starts back up in a clean state. To persist databases, key-value stores, and user uploads, Kubernetes decouples storage management from pod execution using three API primitives:

```text
  [ Pod Spec ]
       │ (mounts Volume)
       ▼
  [ PersistentVolumeClaim (PVC) ]  ───(Requests size & access mode)
       │ (binds to)
       ├──────────────────────────────────────────┐
       ▼ (Static Provisioning)                    ▼ (Dynamic Provisioning)
  [ PersistentVolume (PV) ]               [ StorageClass (SC) ]
       │ (represents)                             │ (provisions PV automatically)
       ▼                                          ▼
  [ Physical Storage ]                     [ Cloud/Local Disk ]
   (HostPath / NFS)                         (EBS / Persistent Disk)
```

---

## Core Concepts

### Core Abstractions

1. **PersistentVolume (PV):** A piece of storage in the cluster that has been provisioned by an administrator or dynamically provisioned using StorageClasses. It represents the physical storage medium (like a local SSD, NFS share, or cloud disk) and has a lifecycle independent of any individual Pod.
2. **PersistentVolumeClaim (PVC):** A request for storage by a user. It specifies the requested size, access modes, and optionally a StorageClass. The control plane automatically searches for a matching PV and binds them together.
3. **StorageClass (SC):** Defines a "profile" of storage (e.g., standard HDD vs. fast SSD) and the provisioner that manages it. It allows PVs to be created **dynamically** when a user requests a PVC, eliminating the need for admins to pre-create physical volumes manually.

### PersistentVolumeClaim (PVC) vs. StorageClass (SC)

| Feature | PersistentVolumeClaim (PVC) | StorageClass (SC) |
| :--- | :--- | :--- |
| **What it is** | A request for storage by a developer. | A template or profile for provisioning storage set up by an administrator. |
| **Who creates it** | The Application Developer. | The Platform, SRE, or Cluster Admin. |
| **Scope** | Namespace-scoped (lives inside your namespace, next to your Pods). | Cluster-scoped (available to all namespaces across the cluster). |
| **Content** | Specifies size and access mode (e.g., "I need 10Gi of RWO storage"). | Specifies storage type and driver (e.g., "Use the AWS EBS driver to make SSDs"). |

---

### Access Modes

When requesting storage via a PVC, you must define its **Access Mode**:

* **ReadWriteOnce (RWO):** The volume can be mounted as read-write by a single Node at a time. Multiple pods on the *same* node can read/write to it, but pods on different nodes cannot.
* **ReadOnlyMany (ROX):** The volume can be mounted as read-only by many Nodes simultaneously.
* **ReadWriteMany (RWX):** The volume can be mounted as read-write by many Nodes simultaneously. This requires shared network filesystems (like NFS, CephFS, or AWS EFS).

---

### Reclaim Policies

A PV's **PersistentVolumeReclaimPolicy** tells the cluster what to do with the physical storage after its PVC is deleted:

* **Retain:** The PV is kept, but marked as `Released`. The data remains intact, preventing other claims from binding to it until an administrator manually cleans up the volume.
* **Delete:** The PV and the underlying physical storage asset (such as a cloud EBS volume) are deleted automatically. (Standard default for dynamic provisioning).

---

## Checklist

* [ ] Define the lifecycle differences between ephemeral and persistent storage.
* [ ] Create a static PersistentVolume using local directories.
* [ ] Deploy a PVC and observe how the control plane binds it to a matching PV.
* [ ] Mount a PVC into a running Pod to write and verify persistent data.
* [ ] Request and verify dynamic volume allocation using a default StorageClass.

---

## Lab

In this lab, you will configure a static PersistentVolume, bind a claim to it, verify data persistence across Pod restarts, and request dynamic storage allocation.

### Steps

1. **Create the Namespace:**
    Apply the namespace manifest:

    ```bash
    kubectl apply -f phase-2/day-11/manifests/01-namespace.yaml
    ```

2. **Deploy and Bind Static Storage:**
    First, create the manual PersistentVolume, which uses a hostPath directory to simulate local storage:

    ```bash
    kubectl apply -f phase-2/day-11/manifests/02-pv-static.yaml
    ```

    Next, apply the PersistentVolumeClaim which requests a matching `1Gi` volume:

    ```bash
    kubectl apply -f phase-2/day-11/manifests/03-pvc-static.yaml
    ```

    Verify the claim has bound successfully to the volume:

    ```bash
    kubectl get pv,pvc -n storage-lab
    ```

    *Expected Outcome:* The status for both the PV and PVC must show as `Bound`.

3. **Mount Storage and Verify Persistence:**
    Deploy a Pod that mounts this static PVC to `/data` and writes a timestamp file:

    ```bash
    kubectl apply -f phase-2/day-11/manifests/04-pod-static.yaml
    ```

    Wait for the Pod to run, then verify the file is written:

    ```bash
    kubectl exec static-writer-pod -n storage-lab -- cat /data/timestamp.txt
    ```

    To prove the data survives container destruction, delete the Pod:

    ```bash
    kubectl delete pod static-writer-pod -n storage-lab
    ```

    Re-deploy the same Pod manifest:

    ```bash
    kubectl apply -f phase-2/day-11/manifests/04-pod-static.yaml
    ```

    Wait for the Pod to initialize and verify that the original timestamp file is still present and readable inside the new container:

    ```bash
    kubectl exec static-writer-pod -n storage-lab -- cat /data/timestamp.txt
    ```

4. **Request Dynamic Storage Allocation:**
    In modern clusters, a default StorageClass (such as `standard` or `gp2`) is configured automatically. Apply the dynamic claim manifest:

    ```bash
    kubectl apply -f phase-2/day-11/manifests/05-pvc-dynamic.yaml
    ```

    Check the claim status:

    ```bash
    kubectl get pvc dynamic-claim -n storage-lab
    ```

    *Expected Outcome:* The status should show `Bound` (or `Pending` if you are on a custom cluster that requires a Pod to trigger provisioning).

    Deploy the reader Pod that mounts this dynamic volume:

    ```bash
    kubectl apply -f phase-2/day-11/manifests/06-pod-dynamic.yaml
    ```

    Verify that the claim binds and the Pod runs:

    ```bash
    kubectl get pods,pvc -n storage-lab
    ```

5. **Clean Up:**
    Delete the namespace and the static PV:

    ```bash
    kubectl delete namespace storage-lab
    kubectl delete pv static-pv
    ```

---

[Back to main README.md](../../README.md)
