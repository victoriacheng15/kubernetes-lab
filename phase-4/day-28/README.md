# Day 28

This day covers cluster-level troubleshooting, including node offline issues, kubelet failures, DNS resolution issues, and container network interface (CNI) problems.

## Concept Overview

Cluster administration requires the ability to troubleshoot components outside of the API server. When a node goes offline or service discovery breaks, you must diagnose the system from the underlying Linux operating system.

```text
               [ Troubleshooting Paths ]
 ┌────────────────────────┼────────────────────────┐
 │                        │                        │
 ▼                        ▼                        ▼
[ Node / Kubelet ]    [ CoreDNS / Service ]   [ CNI / Network ]
 - systemctl status    - kubectl logs kube-dns - /etc/cni/net.d/
 - journalctl -u       - nslookup checks       - IP forwarding
```

---

## Core Concepts

1. **Kubelet Diagnostics:** If a node is `NotReady`, the cause is usually a stopped or misconfigured kubelet daemon. You must troubleshoot using host system tools:
   * `systemctl status kubelet`: Checks if the daemon is active.
   * `journalctl -u kubelet`: Inspects the kubelet logs for boot or connection errors.
2. **Cluster DNS (CoreDNS):** Kubernetes relies on the CoreDNS deployment in the `kube-system` namespace to resolve internal Service names (e.g., `<service>.<namespace>.svc.cluster.local`).
3. **CNI Plugins:** The CNI plugin (e.g., Flannel, Calico, or Cilium) manages pod network allocation. If CNI pods fail, pods cannot acquire IP addresses and remain `ContainerCreating`.
4. **Node Conditions:** Nodes report reasons for failures in their status (such as `MemoryPressure`, `DiskPressure`, `PIDPressure`, or `NetworkUnavailable`).

---

## Checklist

* [ ] Inspect the kubelet system logs and config directory on a host.
* [ ] Test internal cluster DNS resolution using a debug container.
* [ ] Inspect the CoreDNS configuration and log stream.
* [ ] Verify CNI plugin configurations on the node host.

---

## Lab

In this lab, you will debug a mock DNS issue, check active node conditions, and practice running node-level system queries.

### Steps

1. **Verify Node Conditions:**

   Query the cluster nodes to inspect their system conditions:

   ```bash
   kubectl describe nodes | grep -A 8 "Conditions:"
   ```

   *Expected Outcome:* The list displays conditions like `DiskPressure`, `MemoryPressure`, and `Ready`. A healthy node should show `Ready=True` and others as `False`.

2. **Diagnose Kubelet Failures (On Node Host):**

   To simulate host-level troubleshooting (essential for CKA):

   ```bash
   # Check if the service is running
   sudo systemctl status kubelet

   # View the last 50 lines of kubelet logs to locate boot errors
   sudo journalctl -u kubelet -n 50 --no-pager
   ```

3. **Deploy the DNS Troubleshooting Pod:**

   Apply the configuration to launch a network tools container:

   ```bash
   kubectl apply -f phase-4/day-28/manifests/01-dns-check-pod.yaml
   ```

   Wait for the pod to reach `Running` status:

   ```bash
   kubectl get pod dns-test
   ```

4. **Verify DNS Resolution:**

   Execute DNS queries inside the pod to verify the cluster DNS configuration:

   ```bash
   # Resolve the Kubernetes API service address
   kubectl exec dns-test -- nslookup kubernetes.default.svc.cluster.local

   # Resolve an external domain name
   kubectl exec dns-test -- nslookup google.com
   ```

   *Expected Outcome:* The command should print the IP address of the target service or host. If the command fails, the cluster CoreDNS service or its upstream resolvers are failing.

5. **Inspect CoreDNS Logs:**

   If DNS fails, inspect the active CoreDNS deployment logs:

   ```bash
   kubectl logs -n kube-system -l k8s-app=kube-dns
   ```

6. **Inspect CNI Configuration:**

   Locate and inspect the local CNI configuration file on the host to verify network routing setup:

   ```bash
   ls -la /etc/cni/net.d/
   ```

7. **Clean Up:**

   ```bash
   kubectl delete pod dns-test
   ```

---

[Back to main README.md](../../README.md)
