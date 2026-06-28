# Day 17

This day covers running batch workloads using Jobs and schedule-based tasks using CronJobs.

## Concept Overview

Kubernetes Jobs handle run-to-completion workloads, while CronJobs trigger Jobs at scheduled intervals.

```text
[ CronJob Trigger ] (based on schedule, e.g. "*/1 * * * *")
        │
        ▼
   [ Job Created ] ◄─── (runs to completion)
        │
        ├──► [ Pod 1 ] (Success/Fail)
        ├──► [ Pod 2 ] (Success/Fail)
        └──► [ Pod N ] (Success/Fail)
```

---

## Core Concepts

1. **Job:** Spawns one or more Pods to perform a task. It ensures that a specified number of Pods terminate successfully.
2. **CronJob:** Manages Jobs on a time-based schedule (similar to cron in Linux).
3. **RestartPolicy:** For Jobs, the restartPolicy must be set to `OnFailure` or `Never` (it cannot be `Always`).
4. **Completions and Parallelism:**
   - `completions` defines the number of successful Pods needed to finish the Job.
   - `parallelism` defines the maximum number of Pods running simultaneously.
5. **Job and CronJob Limits:**
   - `backoffLimit`: Defines the number of retries before marking the Job as failed (default is 6).
   - `activeDeadlineSeconds`: Specifies a duration limit (in seconds) for how long a Job can run. Once reached, Kubernetes terminates all active Pods and fails the Job.
   - `successfulJobsHistoryLimit` and `failedJobsHistoryLimit`: Control how many completed and failed Job records a CronJob retains in the cluster history (default is 3 successful and 1 failed).
   - `concurrencyPolicy`: Controls how a CronJob behaves if a new execution is scheduled while a previous run is still active. Options are `Allow` (default, run concurrently), `Forbid` (skip the new run), or `Replace` (terminate the active run and start the new one).

---

## Checklist

- [ ] Create a dedicated namespace for the jobs lab.
- [ ] Run a simple single-pod Job to completion and verify logs.
- [ ] Run a parallel Job with completions and parallelism controls.
- [ ] Configure a CronJob that runs every minute and inspect history limits.

---

## Lab

In this lab, you will deploy a single-pod Job, a parallel Job, and a CronJob, and verify their behavior.

### Steps

1. **Create the Namespace:**

   ```bash
   kubectl apply -f day-17/manifests/01-namespace.yaml
   ```

2. **Deploy the Simple Job:**

   ```bash
   kubectl apply -f day-17/manifests/02-simple-job.yaml
   ```

3. **Verify the Simple Job:**

   Wait for the Job to finish:

   ```bash
   kubectl get jobs -n jobs-lab
   ```

   Check the Pod created by the Job:

   ```bash
   kubectl get pods -n jobs-lab
   ```

   Inspect the logs:

   ```bash
   kubectl logs job/simple-job -n jobs-lab
   ```

   *Expected Outcome:* You should see "Starting batch job..." followed by "Batch job completed successfully."

4. **Deploy the Parallel Job:**

   ```bash
   kubectl apply -f day-17/manifests/03-parallel-job.yaml
   ```

5. **Observe Parallel Execution:**

   Monitor the Job:

   ```bash
   kubectl get pods -n jobs-lab -w
   ```

   *Expected Outcome:* You should see exactly 2 Pods running at the same time. Once one finishes, another will start, until 4 Pods complete successfully.

6. **Deploy the CronJob:**

   ```bash
   kubectl apply -f day-17/manifests/04-cronjob.yaml
   ```

7. **Monitor the CronJob:**

   Check the CronJob definition:

   ```bash
   kubectl get cronjob periodic-cronjob -n jobs-lab
   ```

   Wait 1-2 minutes, then check the generated Jobs and Pods:

   ```bash
   kubectl get jobs -n jobs-lab
   kubectl get pods -n jobs-lab
   ```

   *Expected Outcome:* A new Job is spawned every minute. Due to the history limit config, Kubernetes will only retain up to 3 successful Jobs at a time, cleaning up older ones.

8. **Clean Up:**

   ```bash
   kubectl delete namespace jobs-lab
   ```

---

[Back to main README.md](../README.md)
