# 30 Days of Kubernetes 🧪

A practical, day-by-day curriculum for deepening Kubernetes concepts through focused labs, troubleshooting, and reusable notes.

## 🧱 Phase 1: Core Foundations (Days 1–7)

Goal: Understand the Kubernetes control plane, core workload objects, and basic application operation.

- [Day 01](day-01/README.md) - Objective: Understand cluster architecture and core components.
- [Day 02](day-02/README.md) - Objective: Deep dive into Pods, lifecycle, restarts, and init containers.
- [Day 03](day-03/README.md) - Objective: Understand Deployments, ReplicaSets, DaemonSets, StatefulSets, rollouts, and rollbacks.
- [Day 04](day-04/README.md) - Objective: Explore Services, DNS, and service discovery.
- [Day 05](day-05/README.md) - Objective: Use ConfigMaps and Secrets for application configuration.
- [Day 06](day-06/README.md) - Objective: Practice Namespaces, ResourceQuotas, and LimitRanges.
- [Day 07](day-07/README.md) - Project 1: Deploy and troubleshoot a basic multi-pod application.

## 🌐 Phase 2: Scheduling, Networking & Storage (Days 8–14)

Goal: Understand how Kubernetes places workloads, connects services, and persists data.

- [Day 08](day-08/README.md) - Objective: Understand resource requests, limits, and QoS classes.
- [Day 09](day-09/README.md) - Objective: Practice scheduling with node selectors, affinity, and anti-affinity.
- [Day 10](day-10/README.md) - Objective: Use taints and tolerations for scheduling control.
- [Day 11](day-11/README.md) - Objective: Explore PersistentVolumes, PVCs, and StorageClasses.
- [Day 12](day-12/README.md) - Objective: Build NetworkPolicies for ingress and egress control.
- [Day 13](day-13/README.md) - Objective: Configure Ingress and HTTP routing.
- [Day 14](day-14/README.md) - Project 2: Build and troubleshoot a networked application with storage.

## 🔐 Phase 3: Security & Operations (Days 15–21)

Goal: Build operational confidence with access control, health checks, batch workloads, autoscaling, and debugging.

- [Day 15](day-15/README.md) — Objective: Understand RBAC, ServiceAccounts, Roles, ClusterRoles, and bindings.
- [Day 16](day-16/README.md) - Objective: Configure liveness, readiness, and startup probes.
- [Day 17](day-17/README.md) - Objective: Run Jobs and CronJobs.
- [Day 18](day-18/README.md) - Objective: Configure Horizontal Pod Autoscaling.
- [Day 19](day-19/README.md) - Objective: Correlate logs, metrics, events, pod conditions, and node conditions.
- [Day 20](day-20/README.md) - Objective: Debug containers with exec and ephemeral containers.
- [Day 21](day-21/README.md) - Project 3: Deploy a secure, observable, autoscaling application.

## 🚀 Phase 4: Cluster Administration & Recovery (Days 22–30)

Goal: Practice cluster-level administration, recovery, and troubleshooting patterns in Kubernetes.

- Day 22 — Objective: Understand kubeadm cluster setup and node bootstrap.
- Day 23 — Objective: Inspect static pods, control plane manifests, and system components.
- Day 24 — Objective: Practice kubeconfig, certificate inspection, and cluster configuration.
- Day 25 — Objective: Understand cluster upgrades and Kubernetes version skew.
- Day 26 — Objective: Practice node maintenance with cordon, drain, and eviction.
- Day 27 — Objective: Back up and restore etcd.
- Day 28 — Objective: Troubleshoot failed workloads, kubelet issues, nodes, DNS, and networking.
- Day 29 — Project 4: Recover a broken cluster and restore application availability.
- Day 30 — Final Capstone: Build a troubleshooting and operations lab.

## 📚 Appendix A: The Conceptual Framework (Optional)

Goal: Master the core system designs, Linux primitives, and control plane mechanics that underpin Kubernetes architecture.

- Day A1 - Objective: Cluster Management: Compute Abstraction & Control Planes.
    *   *Lab Idea:* Build a multi-node cluster from scratch using `kubeadm` and simulate control plane failures.
- Day A2 - Objective: Networking: Packet Routing & Policy Enforcement.
    *   *Lab Idea:* Trace IP packet routing and apply network policies inside a local containerized sandbox (such as Kind or Minikube) to avoid modifying host-level network interfaces.
- Day A3 - Objective: Infrastructure Automation & GitOps: Declarative State & Reconciliation.
    *   *Lab Idea:* Deploy ArgoCD or Flux to demonstrate pull-based reconciliation and drift correction.
- Day A4 - Objective: Container Runtimes: Linux Isolation Primitives.
    *   *Lab Idea:* Isolate a process manually using Linux namespaces and cgroups inside a disposable container or virtual machine.
- Day A5 - Objective: Security: Least Privilege & Admission Control.
    *   *Lab Idea:* Deploy a custom admission webhook to validate or mutate resource specifications before persistence.
- Day A6 - Objective: Observability: Telemetry Collection & Distributed Debugging.
    *   *Lab Idea:* Configure an OpenTelemetry Collector to unify metrics, structured logs, and tracing.

## 📚 Resources and Links

- Kubernetes docs: https://kubernetes.io/docs/
- Kubernetes tasks: https://kubernetes.io/docs/tasks/
- kubectl reference: https://kubernetes.io/docs/reference/kubectl/
- CKA curriculum: https://github.com/cncf/curriculum
