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

Use:

```
./github-arc-setup.sh --token <TOKEN>
```

---

## 🚀 Usage Summary

1. Run setup script  
2. Generate a runner YAML per repo  
3. Apply the YAML via `kubectl`  
4. Ensure each repo includes `copilot-setup-steps.yml`  
5. Copilot Agent will use your local ARC/Minikube runners

---

