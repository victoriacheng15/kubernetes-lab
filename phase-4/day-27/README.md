# Day 27

This day covers etcd backup and restore workflows, which are essential tasks for cluster recovery and control plane maintenance.

## Concept Overview

etcd is the key-value database that stores the complete configuration and state of a Kubernetes cluster. If etcd suffers corruption or data loss, the cluster cannot function. Backing up etcd regularly and knowing how to restore it is a critical skill for cluster administrators.

```text
[ active etcd ] ──► (etcdctl snapshot save) ──► [ snapshot.db ] (Backup file)
       │
       ▼ (Corruption occurs)
[ Stop api-server & etcd ]
       │
       ▼
[ Restore snapshot ] ──► (etcdctl snapshot restore) ──► [ New etcd Data Dir ]
       │
       ▼
[ Start etcd & api-server ] ──► [ Restored Cluster State ]
```

---

## Core Concepts

1. **etcdctl:** The command-line client used to interact with etcd databases. It requires setting `ETCDCTL_API=3` to use the V3 API version used by Kubernetes.
2. **etcd Certificates:** To authenticate with the secure etcd cluster, you must present valid TLS client certificates (`server.crt` and `server.key`) and the trusted CA certificate (`ca.crt`). These are located in `/etc/kubernetes/pki/etcd/`.
3. **etcd Snapshot:** A point-in-time binary copy of the etcd database state.
4. **etcd Restore Lifecycle:**
   * Stop the Kubernetes API Server and etcd services (by moving their static pod manifests out of the watched `/etc/kubernetes/manifests/` directory).
   * Run the restore command to initialize a new cluster member database directory from the snapshot.
   * Swap the old etcd data directory (usually `/var/lib/etcd`) with the new, restored data directory.
   * Restart the control plane services by moving the manifests back to the static pod directory.

---

## Checklist

* [ ] Inspect a sample etcd static pod configuration file.
* [ ] Take a snapshot of the etcd database using `etcdctl`.
* [ ] Verify the integrity of the taken snapshot.
* [ ] Practice the control plane teardown and restore workflow.

---

## Lab

In this lab, you will practice backing up an etcd database and simulating the steps to restore a snapshot.

### Steps

1. **Inspect etcd Configuration:**

   Open and inspect [01-etcd-pod.yaml](manifests/01-etcd-pod.yaml). Look at how the host path volumes are mapped for the client certificates (`/etc/kubernetes/pki/etcd`) and the datastore directory (`/var/lib/etcd`).

2. **Run an etcd Snapshot Backup:**

   To create a snapshot named `snapshot.db`, run the `etcdctl snapshot save` command. You must provide the endpoint and authentication certificates:

   ```bash
   # Set the API version to V3
   export ETCDCTL_API=3

   # Take the backup
   sudo etcdctl --endpoints=https://127.0.0.1:2379 \
     --cacert=/etc/kubernetes/pki/etcd/ca.crt \
     --cert=/etc/kubernetes/pki/etcd/server.crt \
     --key=/etc/kubernetes/pki/etcd/server.key \
     snapshot save /tmp/snapshot.db
   ```

   *(Note: For K3s environments, K3s does not run etcd by default if it was installed with SQLite, but if it runs in multi-master/HA mode, K3s manages etcd snapshots natively via the command `k3s etcd-snapshot save`)*.

3. **Verify the Snapshot:**

   Confirm that the snapshot was written successfully and is valid:

   ```bash
   sudo etcdctl --write-out=table snapshot status /tmp/snapshot.db
   ```

   *Expected Outcome:* The command displays a table showing the snapshot's revision number, total size, and hash value.

4. **Restore the Snapshot:**

   To restore the snapshot to a new data directory:

   ```bash
   # 1. Restore the snapshot files to a temporary directory
   sudo etcdctl --data-dir=/var/lib/etcd-restored \
     snapshot restore /tmp/snapshot.db
   ```

5. **Swap the etcd Data Directories:**

   To complete the restore in a live cluster:

   ```bash
   # 1. Stop control plane components to prevent writes during restore:
   sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
   sudo mv /etc/kubernetes/manifests/etcd.yaml /tmp/

   # 2. Back up the current active etcd database and replace it:
   sudo mv /var/lib/etcd /var/lib/etcd-backup
   sudo mv /var/lib/etcd-restored /var/lib/etcd

   # 3. Restart the components by restoring their manifest files:
   sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
   sudo mv /tmp/etcd.yaml /etc/kubernetes/manifests/
   ```

---

[Back to main README.md](../../README.md)
