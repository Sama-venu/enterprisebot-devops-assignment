# Part 4 - Findings

I was able to identify and fix a few issues in the broken Helm chart within the time limit. While working on it, I tried to fix one problem at a time instead of changing multiple things together. After every fix I redeployed the chart and checked how the behavior changed before moving to the next issue.

---

## Defect 1

### Symptom

After deploying the chart, not all workloads were coming up successfully. Some pods were failing to start properly and `./scenario.sh verify` was already showing multiple failures.

### Cause

The Deployment templates were using an incorrect `runAsUser` value in the security context. Because of that, the containers were not starting correctly.

### Fix

Updated the `securityContext` in the affected deployment YAML files and changed the `runAsUser` value to the correct non-root user.

### How I found it

I first checked the pod status.

```bash
kubectl get pods -n debug-lab
```

Then I looked at the pod events and logs.

```bash
kubectl describe pod <pod-name> -n debug-lab
kubectl logs <pod-name> -n debug-lab
```

The pod events were pointing to a startup issue, so I checked the deployment YAMLs and noticed the security context configuration. After updating it and deploying again, those pods started normally.

---

## Defect 2

### Symptom

The reporter pod was still not becoming Ready even though the container was running.

The logs showed:

```
eb-debug-app 2.0.0 starting...
listening on :8081
```

But the readiness probe was checking port 8080.

### Cause

The application image listens on port 8081 by default. Since the `PORT` environment variable was not set, the application never listened on port 8080, so the readiness probe kept failing.

### Fix

Added the following environment variable to the reporter deployment.

```yaml
- name: PORT
  value: "8080"
```

### How I found it

I checked the pod description first because the pod was staying in 0/1 Ready.

```bash
kubectl describe pod reporter-<pod> -n debug-lab
```

The readiness probe was continuously failing, so I checked the container logs.

```bash
kubectl logs reporter-<pod> -n debug-lab
```

The logs clearly showed the application was listening on port 8081 instead of 8080, so I added the missing environment variable and deployed the chart again.

---

## Defect 3

### Symptom

After fixing the port issue, the reporter pod was still not becoming Ready.

This time the logs showed:

```
pods is forbidden:
User "system:serviceaccount:debug-lab:reporter"
cannot list resource "pods"
```

### Cause

The reporter ServiceAccount did not have permission to list pods.

There was already an RBAC configuration, but it was bound to the default ServiceAccount instead of the reporter ServiceAccount.

### Fix

Created a Role and RoleBinding for the reporter ServiceAccount and granted permission to get and list pods.

I also verified the permission using:

```bash
kubectl auth can-i list pods \
--as=system:serviceaccount:debug-lab:reporter \
-n debug-lab
```

The output returned:

```
yes
```

### How I found it

Once the port issue was fixed, the error changed completely. Instead of connection refused, I started getting HTTP 403 errors in the logs.

That told me the application itself was running now, but it didn't have enough permissions to talk to the Kubernetes API.

I checked the ServiceAccount, Role and RoleBinding resources, fixed the RoleBinding, redeployed the chart and verified the permissions using `kubectl auth can-i`.

---

## Remaining Issues

After fixing the RBAC issue, the reporter logs changed again.

Instead of the permission error, I started getting:

```
parse pod list: unexpected end of JSON input
```

At the same time, the metrics deployment was still not becoming Ready and the verify script was still reporting a few failed checks.

Because of the assignment time limit, I stopped my investigation here instead of trying random changes.

If I had more time, my next steps would be:

- Check why the reporter is failing to parse the pod list response.
- Investigate why the metrics deployment is not becoming Ready.
- Verify the backend health endpoint.
- Re-run `./scenario.sh verify` after each fix until all checks pass.

Overall, I tried to follow the same approach I would use during a production issue: fix one problem, verify the result, then move on to the next symptom instead of making multiple changes at once.
