# self-hosted-github-copilot-agent-runner

Central repo to manage self-hosted GitHub Copilot agent runners (via ARC) for multiple repositories.

Each supported repo gets its own `RunnerDeployment` YAML generated from a shared template using a small Node.js script.

---

## Prerequisites

- Node.js installed (for the generator script)
- `kubectl` configured to talk to your cluster
- Actions Runner Controller (ARC) installed
- Namespace `actions-runner-system` exists (default for ARC)

---

## Generate a runner for a repository

From the repo root, run:

```bash
node scripts/generate-runner.js <repo-name>
```

Examples:

```bash
node scripts/generate-runner.js openwebui-sql-tool-server-api
node scripts/generate-runner.js autogen-playground
```

This will create files like:

- `runners/openwebui-sql-tool-server-api-runner.yml`
- `runners/autogen-playground-runner.yml`

Each file contains a `RunnerDeployment` bound to `isNotOkay/<repo-name>` and a unique `metadata.name` like:

```yaml
metadata:
  name: copilot-agent-runner-openwebui-sql-tool-server-api
```

---

## Apply the runner to the cluster

After generating a runner file, apply it with `kubectl`:

```bash
kubectl apply -f runners/openwebui-sql-tool-server-api-runner.yml
kubectl apply -f runners/autogen-playground-runner.yml
```

You can re-apply the same files later if you change the template or env vars:

```bash
kubectl apply -f runners/<repo-name>-runner.yml
```

---

## Check if the runner pods are running

### List pods in the ARC namespace

```bash
kubectl get pods -n actions-runner-system
```

You should see pods with names derived from your runner deployments, e.g.:

```text
copilot-agent-runner-openwebui-sql-tool-server-api-xxxxx
```

### Check RunnerDeployment status

```bash
kubectl get runnerdeployments -n actions-runner-system
```

Or with more detail:

```bash
kubectl describe runnerdeployment copilot-agent-runner-openwebui-sql-tool-server-api -n actions-runner-system
```

### Inspect pod logs (for debugging)

Pick a pod name from `kubectl get pods` and run:

```bash
kubectl logs -n actions-runner-system <pod-name>
```

This is useful if the runner isn’t registering correctly with GitHub or crashing on startup.

---

## Template & Script

- All runners are generated from:  
  `runners/template.yml`

- Generator script (cross-platform, Node.js):  
  `scripts/generate-runner.js`

The script:
- Replaces `{{REPO}}` with the raw repo name (e.g. `openwebui-sql-tool-server-api`)
- Replaces `{{REPO_NAME}}` with a sanitized name prefixed with `copilot-agent-runner-`
- Writes the final YAML to `runners/<repo-name>-runner.yml`
