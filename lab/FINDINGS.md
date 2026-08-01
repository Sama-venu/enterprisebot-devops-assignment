# Findings — Part 4 debug lab

Fill in one entry per defect you find. Paste the *actual* output you saw —
we cross-check it against your session recording and your git diff, and the
diagnostic path matters more to us than the fix itself.

Before you start investigating, begin recording:
`script -q part4-session.log` (or `asciinema rec part4-session.cast`), and
commit that file alongside this one.

---

## Defect 1

**Symptom**

After running the lab, not all deployments became healthy.

```text
PASS  migrate Job completed
PASS  deployment backend: 1/1 ready
PASS  deployment gateway: 1/1 ready
PASS  deployment worker: 1/1 ready
FAIL  deployment reporter: 0/1 ready
FAIL  deployment metrics: 0/1 ready
```

Some pods were also failing to start correctly because of the security context configuration.

**Cause**

The deployment manifests were using an incorrect `runAsUser` configuration. The application image is expected to run as a non-root user, but the security context values were not correct for the image.

**Fix**

Updated the `securityContext` in the affected deployment YAML files to use the correct non-root user.

I chose to fix the manifests instead of removing the security context because running containers as non-root is the correct approach.

**How I found it**

I first checked the overall status.

```bash
kubectl get pods -n debug-lab
```

Then I inspected the failing pods.

```bash
kubectl describe pod <pod-name> -n debug-lab
kubectl logs <pod-name> -n debug-lab
```

The pod events pointed to a startup issue instead of an application bug, so I reviewed the deployment YAMLs and corrected the security context.

---

## Defect 2

**Symptom**

Reporter deployment stayed at **0/1 Ready**.

`kubectl describe pod` showed continuous readiness probe failures.

```
Readiness probe failed:
Get "http://10.244.0.16:8080/healthz":
dial tcp 10.244.0.16:8080:
connect: connection refused
```

The application logs showed:

```
eb-debug-app 2.0.0 starting:
mode=reporter
listening on :8081
(image default is 8081; set PORT to override)
```

**Cause**

The application listens on port **8081** by default.

The readiness probe was checking port **8080**, so Kubernetes never marked the pod as Ready.

**Fix**

Added the following environment variable in `reporter.yaml`.

```yaml
- name: PORT
  value: "8080"
```

This makes the application listen on the same port used by the Service and readiness probe.

**How I found it**

I checked the pod details.

```bash
kubectl describe pod reporter-xxxxx -n debug-lab
```

Then I checked the application logs.

```bash
kubectl logs reporter-xxxxx -n debug-lab
```

The logs clearly showed the application listening on port 8081, which matched the readiness failures.

---

## Defect 3

**Symptom**

After fixing the port issue, the readiness probe still failed.

The logs changed to:

```
pod list failed:

User "system:serviceaccount:debug-lab:reporter"

cannot list resource "pods"

code=403
```

**Cause**

The reporter ServiceAccount did not have permission to list pods.

The existing RoleBinding was attached to the default ServiceAccount instead of the reporter ServiceAccount.

**Fix**

Created a new Role and RoleBinding for the reporter ServiceAccount and granted permission to list pods.

Verified using:

```bash
kubectl auth can-i list pods \
--as=system:serviceaccount:debug-lab:reporter \
-n debug-lab
```

Output:

```
yes
```

**How I found it**

Once the application started successfully, the error changed from connection failures to RBAC errors.

I checked:

```bash
kubectl get role -n debug-lab

kubectl get rolebinding -n debug-lab -o yaml

kubectl get sa reporter -n debug-lab
```

I noticed the existing RoleBinding was pointing to the default ServiceAccount, so I created a new RoleBinding for the reporter ServiceAccount.

---

## Defect 4

**Symptom**

After fixing RBAC, reporter was still not becoming Ready.

Logs changed again.

```
pod list failed:
parse pod list:
unexpected end of JSON input
```

Readiness continued returning HTTP 503.

**Cause**

I could not complete the root cause within the assignment time.

The RBAC issue was fixed, but another application or configuration issue still remained.

**Fix**

Not completed.

**How I found it**

After fixing RBAC I restarted the deployment.

```bash
kubectl rollout restart deployment reporter -n debug-lab
```

Then checked the logs again.

```bash
kubectl logs reporter-xxxxx -n debug-lab
```

The error had changed completely, which confirmed the previous RBAC issue was resolved and another issue was now exposed.

---

## Defect 5

**Symptom**

Metrics deployment never became ready.

`./scenario.sh verify`

```
FAIL deployment metrics: 0/1 ready
```

**Cause**

Not investigated completely because I spent most of the available time working through the reporter issues.

**Fix**

Not completed.

**How I found it**

I planned to investigate using:

```bash
kubectl get pods -n debug-lab

kubectl describe pod

kubectl logs
```

after reporter became healthy.

---

## Defect 6

**Symptom**

Final verification still showed multiple failing checks.

```
FAIL deployment reporter: 0/1 ready
FAIL deployment metrics: 0/1 ready
FAIL ServiceAccount debug-lab/reporter cannot list pods
FAIL backend does not answer on http://backend:8080/healthz
FAIL gateway /status does not report backend=ok
FAIL reporter /report does not return a pod count
```

Some of these failures were secondary effects caused by reporter and metrics not becoming healthy.

**Cause**

Not completed within the assignment time.

Several remaining failures were dependent on fixing the reporter completely before moving to the next components.

**Fix**

Not completed.

**How I found it**

I repeatedly verified progress using:

```bash
./scenario.sh verify
```

After every change, I compared the output to see whether the symptom changed before moving to the next investigation.

---

## Time limit

I stopped the investigation after the assignment time limit.

The next steps I would have taken are:

- Investigate why the reporter returns `unexpected end of JSON input`.
- Check whether the Kubernetes API response received by the application is malformed or whether another required configuration is missing.
- Investigate the metrics deployment using `kubectl describe` and `kubectl logs`.
- Run `./scenario.sh verify` after each fix until every check passes.
- Remove any temporary or duplicate RBAC manifests once the final solution is verified.
---

If you ran out of time on any defect, say so here and describe what you would
have tried next — that section is read carefully and counts in your favour.
