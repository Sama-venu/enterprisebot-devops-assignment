This repository contains my solution for the Enterprise Bot DevOps assignment.

The project includes:

- Part 1 - Containerized Python service
- Part 2 - Helm chart
- Part 3 - One-command setup using Kind
- Part 4 - Kubernetes debugging lab
- Part 5 - Written question
- part 6 - How to verify my work

---

# How to run

### Clone the repository

```bash
git clone https://github.com/Sama-venu/enterprisebot-devops-assignment.git
cd enterprisebot
```

### Run the setup

```bash
chmod +x setup.sh
./setup.sh
```

The script will:

- Create (or reuse) a Kind cluster named `demo`
- Install ingress-nginx
- Build the application image
- Load the image into Kind
- Deploy the Helm chart into namespace `demo`

The script can be executed multiple times without failing.

---

# How to verify

Check that all pods are running.

```bash
kubectl get pods -n demo
```

Check the service.

```bash
kubectl get svc -n demo
```

Verify the application.

```bash
kubectl port-forward svc/demo 8080:80 -n demo
```

Then open

```
http://localhost:8080/
```

or

```bash
curl http://localhost:8080/
```

Health endpoint

```bash
curl http://localhost:8080/healthz
```

---

# Resource requests and limits

I kept the resource values small because this assignment runs on a local Kind cluster and the application itself is lightweight.

Current values:

```yaml
requests:
  cpu: 100m
  memory: 128Mi

limits:
  cpu: 200m
  memory: 256Mi
```

These values are enough for a simple HTTP application while still allowing Kubernetes to schedule the pods properly.

For a real production application, I would not simply guess these numbers. I would collect CPU and memory usage over time using Prometheus or another monitoring tool and then tune the requests and limits based on actual usage.

---

# What I deliberately skipped

Because of the time limit, I decided not to spend extra time adding features that were not required by the assignment.

I also could not finish all the issues in the debugging lab. I fixed a few defects and documented my investigation, but I stopped once the assignment time was over instead of continuing until every check passed.

I also skipped things like:

- Horizontal Pod Autoscaler
- Network Policies
- PodDisruptionBudget
- External Secrets
- CI/CD pipeline

The risk of skipping these is that the deployment is good enough for a demo environment, but it is not ready for a production workload.

---

# What I would change for production

If this application was going to production, I would improve a few areas.

- Add CI/CD using GitHub Actions or Jenkins
- Scan container images before deployment
- Store secrets using Kubernetes Secrets or an external secret manager
- Add Horizontal Pod Autoscaler
- Add PodDisruptionBudget
- Enable Network Policies
- Configure proper monitoring and alerting with Prometheus and Grafana
- Add centralized logging
- Improve ingress security with TLS and security headers
- Add automated Helm tests before deployment

These changes would make the application easier to operate and much safer in a production environment.

#  How I used AI

I used ChatGPT mainly as a technical troubleshooting assistant whenever I got stuck during the assignment. I did not apply suggestions directly without testing them in my local kind cluster.

Specifically, AI helped me with:

Helped me identify the mismatch between the application listening port (8081) and the Kubernetes readiness probe configured for port 8080. Based on that, I added the PORT=8080 environment variable to the reporter deployment.
Helped me troubleshoot the repeated readiness probe failures by interpreting the output from kubectl describe pod and kubectl logs, instead of guessing from the YAML files.
Guided me through debugging the RBAC issue after the reporter logs showed 403 Forbidden, including checking the ServiceAccount, Role and RoleBinding, and verifying permissions using kubectl auth can-i.
Helped me understand why the symptom changed from 403 Forbidden to parse pod list: unexpected end of JSON input, and explained that fixing one issue can expose the next issue in a Kubernetes application.
Suggested checking the rollout status, pod events and ReplicaSets after updating the Helm chart, which helped me verify whether my changes were actually applied.
