# 🛠 Self-Hosted GitHub Copilot Agent Runner (ARC + Minikube)

This repository contains everything required to run **self-hosted GitHub Copilot Agent runners** for *individual repositories* using:

- **GitHub Actions Runner Controller (ARC)**
- **Minikube (local Kubernetes)**
- A **template-based RunnerDeployment generator**

Because personal GitHub accounts do **not** have an organization by default, ARC cannot manage organization-level runners.  
➡️ **This project enables per-repository runners instead.**

---

## 📌 Overview

This project includes:

### 1️⃣ `github-arc-setup.sh`
A full bootstrap script that:

- Installs all required tools  
  (.NET 9 SDK, Node.js 20, Docker, kubectl, Minikube, Helm, cert-manager, ARC)
- Creates the GitHub token secret for ARC
- Auto-resets ARC if previously installed
- Prepares everything so that RunnerDeployment YAMLs can be applied

📢 **This script must be executed before anything else.**

---

### 2️⃣ A RunnerDeployment **template**

Located at:

```
/runners/template.yml
```

The template includes placeholders (`{{REPO}}`, `{{REPO_NAME}}`) that will be replaced during YAML generation.

Every repository that should use a Copilot Agent runner **must generate its own RunnerDeployment YAML** using this template.

---

### 3️⃣ A YAML generator script

Located at:

```
/scripts/generate-runner.js
```

Usage:

```bash
node generate-runner.js <repo-name>
```

Example:

```bash
node generate-runner.js my-awesome-repo
```

This produces:

```
/runners/my-awesome-repo-copilot-agent-runner.yml
```

The script:

- Sanitizes the repository name
- Applies the template
- Ensures `metadata.name` is correct
- Writes a complete runnable ARC YAML

---

## 🔐 Required GitHub Token

The setup script requires a **classic GitHub Personal Access Token** with the following scopes:

| Scope | Purpose |
|-------|---------|
| `repo` | Required for repository runners |
| `workflow` | Allows GitHub Actions workflows to run |
| `admin:repo_hook` | Needed for ARC's webhook operations |

Pass it using:

```bash
./github-arc-setup.sh --token <YOUR_GITHUB_CLASSIC_TOKEN>
```

A token already exists with the required permissions:

> **Token name:** `self hosted github copilot agent runner`

---

## ⚠️ Script Must Be Executed Twice

During the **first run**, the script installs Docker and will output a message stating that your user must be added to the Docker group.

To fix this:

```bash
sudo usermod -aG docker $USER
newgrp docker
```

Alternatively log out and back in.

Then re-run the script:

```bash
./github-arc-setup.sh --token <YOUR_TOKEN>
```

On the second run, everything completes successfully.

---

## 🚀 After Setup

### 1️⃣ Generate a RunnerDeployment YAML for each repository

Example:

```bash
node scripts/generate-runner.js project-x
```

Apply it:

```bash
kubectl apply -f runners/project-x-copilot-agent-runner.yml
```

### 2️⃣ Verify runner pods

```bash
kubectl get pods -n actions-runner-system
```

You should see ephemeral runners starting.

---

## 📁 Project Structure

```
.
├── github-arc-setup.sh        # Full ARC + Minikube installer
├── runners/
│   ├── template.yml           # Base RunnerDeployment template
│   └── *.yml                  # Generated runner YAMLs for each repo
└── scripts/
    └── generate-runner.js     # Script that creates per-repository YAMLs
```

---

## ❓ Why is this needed?

Personal GitHub accounts **do not have an organization**, which prevents:

- Organization-wide runners
- Organization-level ARC management

Therefore:

- ARC must register **repository-scoped runners**
- Each repository requires a dedicated RunnerDeployment YAML
- This project automates that entire workflow

---

## ✅ Summary

| Feature | Supported |
|---------|-----------|
| Self-hosted Copilot Agent runners | ✔ |
| Per-repository RunnerDeployment generation | ✔ |
| Full environment auto-setup (Docker, kubectl, Helm, etc.) | ✔ |
| Classic token authentication | ✔ |
| Runs locally via Minikube | ✔ |

