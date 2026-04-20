# 🛠 Self-Hosted GitHub Copilot Agent Runner (ARC + Minikube)

This repository provides a complete setup for running **self-hosted GitHub Copilot Agent runners** on a personal GitHub account using:

- **GitHub Actions Runner Controller (ARC)**
- **Minikube (local Kubernetes)**
- **Template-based RunnerDeployment generation**

Because personal GitHub accounts do not include organizations, ARC cannot manage org-level runners.  
➡️ **This project enables repository-specific Copilot Agent runners instead.**

---

## 📌 Components

### 1️⃣ `github-arc-setup.sh`
A bootstrap script that installs all required tools (Docker, kubectl, Minikube, Helm, cert-manager, ARC, .NET, Node.js) and configures ARC with your GitHub token.

> **Run twice** if Docker group membership is required.

---

### 2️⃣ RunnerDeployment Template
Located in:

```
/runners/template.yml
```

Used to generate **per-repository** ARC RunnerDeployments.

---

### 3️⃣ YAML Generator Script

```
node scripts/generate-runner.js <repo-name>
```

Creates:

```
/runners/<repo-name>-copilot-agent-runner.yml
```

Apply with:

```
kubectl apply -f runners/<file>.yml
```

---

### 4️⃣ Repository-Specific Copilot Setup Workflow

Every repo that uses your self-hosted Copilot Agent must contain:

```
.github/workflows/copilot-setup-steps.yml
```

Example:

```yaml
name: "Copilot Setup Steps"

on:
  workflow_dispatch:
  push:
    paths:
      - .github/workflows/copilot-setup-steps.yml
  pull_request:
    paths:
      - .github/workflows/copilot-setup-steps.yml

jobs:
  copilot-setup-steps:
    runs-on: copilot-agent-runners

    permissions:
      contents: read

    steps:
      - uses: actions/checkout@v4

      - name: Display environment information
        run: |
          dotnet --info || echo "dotnet not found"
          node --version || echo "node not found"
          npm --version || echo "npm not found"

      - name: Verify environment
        run: |
          dotnet --list-sdks || echo "No SDKs"
          node -e "console.log('Node OK')" || echo "Node failed"
```

📌 **Purpose:**  
This workflow prepares the environment the Copilot Agent will use.  
Its contents should match the repository’s tech stack.

---

## 🔐 Required GitHub Token

A **classic PAT** with:

- `repo`
- `workflow`
- `admin:repo_hook`

Usage:

```
chmod +x github-arc-setup.sh
./github-arc-setup.sh --token <TOKEN>
```

⚠️ Important:
- Do NOT use GitHub Actions `GITHUB_TOKEN`
- Token must belong to a user with admin access to the repo

---

## 👀 Watching Runner Pods in Real Time

Copilot Agent runners are typically **ephemeral**.  
Pods are created **only when a GitHub Actions job is scheduled**, and are deleted after the job completes.

```
kubectl get pods -n actions-runner-system -w
```

```
kubectl get pods -n actions-runner-system -l actions.summerwind.dev/runner
```

---

## 🧹 Permanently Deleting All Runner Pods

```
kubectl delete namespace actions-runner-system
```

⚠️ Only do this if you no longer need ARC.

---

## 🚀 Usage Summary

1. Run setup script
2. Generate a runner YAML per repository
3. Apply the YAML via `kubectl`
4. Ensure each repo includes `copilot-setup-steps.yml`
5. Watch runner pods appear during GitHub Actions runs
6. Copilot Agent will use your local ARC/Minikube runners

---

# 🧩 Troubleshooting

## ❗ No Runner Pods Are Created

If:

```
kubectl get pods -n actions-runner-system
```

and:

```
kubectl get runnerdeployments -n actions-runner-system
```

shows:

```
DESIRED: 2
CURRENT: 0
AVAILABLE: 0
```

➡️ ARC is failing before Pod creation.

---

## 🔍 Check Controller Logs

```
kubectl logs -n actions-runner-system deploy/actions-runner-controller -c manager --since=10m
```

---

## 🚨 401 Bad credentials

Example:

```
FailedUpdateRegistrationToken
401 Bad credentials
POST https://api.github.com/repos/<repo>/actions/runners/registration-token
```

➡️ Your GitHub token is invalid.

---

## 🔐 Fix Token

```
kubectl create secret generic controller-manager   -n actions-runner-system   --from-literal=github_token='<NEW_PAT>'   -o yaml --dry-run=client | kubectl apply -f -
```

```
kubectl rollout restart deployment/actions-runner-controller -n actions-runner-system
```

---

## ✅ Verify Fix

```
kubectl logs -n actions-runner-system deploy/actions-runner-controller -c manager --since=5m
```

Then:

```
kubectl get runnerdeployments -n actions-runner-system
kubectl get pods -n actions-runner-system -w
```

---

## ⚠️ GitHub Shows Runners but No Pods

GitHub UI may show stale runners.

➡️ Always trust Kubernetes state.

---

## 🧠 Key Insight

If RunnerDeployment exists but CURRENT = 0 → almost always authentication issue.

---

## 🔧 Debug Commands

```
kubectl get runnerdeployments,runnerreplicasets,runners -n actions-runner-system
kubectl get pods -n actions-runner-system -w
kubectl get events -n actions-runner-system --sort-by=.metadata.creationTimestamp
kubectl logs -n actions-runner-system deploy/actions-runner-controller -c manager --tail=200
```
