# Day 20

This day covers interactive container debugging using `kubectl exec` and injecting Ephemeral Containers with `kubectl debug`.

## Concept Overview

For containers with troubleshooting utilities installed, `kubectl exec` allows running commands interactively. For minimal or distroless containers lacking shells or tools, `kubectl debug` allows injecting an ephemeral troubleshooting container into the pod sandbox.

```text
           [ Pod Sandbox ]
 ┌─────────────────┴─────────────────┐
 │                                   │
 │  [ Target Container ]             │ ◄─── (Distroless/Minimal)
 │                                   │
 │  [ Ephemeral Container ]          │ ◄─── (Injected via kubectl debug)
 │                                   │
 └───────────────────────────────────┘
```

---

## Core Concepts

1. **kubectl exec:** Runs a process inside an existing container. Requires the target container to contain the necessary shell binaries (such as `sh` or `bash`).
2. **Ephemeral Containers:** Temporary containers that run within an existing Pod's sandbox to support troubleshooting. They do not have resource guarantees, cannot be restarted, and are added dynamically using `kubectl debug`.
3. **Target Container Process Sharing:** When debugging, using `--target` allows the ephemeral container to share the target container's process namespace, enabling utilities like `ps` to see the target processes.
4. **Distroless/Minimal Images:** High-security and low-overhead images that do not contain packages, package managers, or shells, rendering standard `exec` debugging impossible.

---

## Checklist

- [ ] Create a dedicated namespace for the debugging lab.
- [ ] Deploy a standard container and interact with it using `kubectl exec`.
- [ ] Deploy a minimal/distroless container and observe standard `exec` failure.
- [ ] Inject an ephemeral container into the distroless pod using `kubectl debug`.
- [ ] Verify process sharing and investigate the target container filesystem.

---

## Lab

In this lab, you will practice troubleshooting standard and distroless pods using `kubectl exec` and `kubectl debug`.

### Steps

1. **Create the Namespace:**

   ```bash
   kubectl apply -f phase-3/day-20/manifests/01-namespace.yaml
   ```

2. **Deploy the Standard Pod:**

   ```bash
   kubectl apply -f phase-3/day-20/manifests/02-standard-pod.yaml
   ```

3. **Verify Standard Debugging with Exec:**

   Run an interactive shell inside the running container:

   ```bash
   kubectl exec -it standard-pod -n debugging-lab -- sh
   ```

   Inside the shell, list the directories and files:

   ```bash
   ls -la
   exit
   ```

   *Expected Outcome:* The command opens a shell prompt successfully because the Alpine base image contains shell binaries.

4. **Deploy the Distroless/Minimal Pod:**

   ```bash
   kubectl apply -f phase-3/day-20/manifests/03-distroless-pod.yaml
   ```

5. **Attempt Exec on Distroless Pod:**

   Try to run a shell command inside the distroless container:

   ```bash
   kubectl exec -it distroless-pod -n debugging-lab -- sh
   ```

   *Expected Outcome:* The command fails with an error similar to `OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH: unknown`.

6. **Debug Using an Ephemeral Container:**

   Since standard exec failed, use `kubectl debug` to inject an ephemeral debugging container:

   ```bash
   kubectl debug -it distroless-pod -n debugging-lab --image=alpine:3.18 --target=app
   ```

   Inside the interactive session that opens, check running processes:

   ```bash
   ps aux
   ```

   *Expected Outcome:* You will see the shell process from alpine alongside the process from the target container (`pause` process with PID 1), thanks to the namespace sharing triggered by `--target=app`.

   Exit the session:

   ```bash
   exit
   ```

7. **Verify Ephemeral Container Status:**

   Describe the pod to view the ephemeral container status:

   ```bash
   kubectl describe pod distroless-pod -n debugging-lab
   ```

   *Expected Outcome:* Under the "Ephemeral Containers" section, you will see the injected alpine container, its state, and its properties.

8. **Clean Up:**

   ```bash
   kubectl delete namespace debugging-lab
   ```

---

[Back to main README.md](../../README.md)
