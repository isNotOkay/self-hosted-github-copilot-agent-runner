#!/bin/bash
set -e

# =============================================================================
# GitHub Actions Runner Controller (ARC) Setup Script - Auto Reset
# =============================================================================

echo "========================================="
echo "GitHub ARC Setup Script (Token Required & Auto Reset ARC)"
echo "========================================="

GITHUB_TOKEN=""
GITHUB_REPO=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --token) GITHUB_TOKEN="$2"; shift 2 ;;
    --repo) GITHUB_REPO="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: $0 --token <GITHUB_TOKEN> [--repo owner/repo]"
      exit 0 ;;
    *)
      echo "❌ Unknown option: $1"
      exit 1 ;;
  esac
done

# --------------------------- TOKEN CHECK ---------------------------
if [ -z "$GITHUB_TOKEN" ]; then
  echo "❌ ERROR: GitHub token is required."
  echo "   Use: $0 --token <YOUR_GITHUB_PAT>"
  exit 1
fi
echo "✅ GitHub token detected. Continuing..."

# --------------------------- 1. System Update ---------------------------
echo "[1/13] Updating system..."
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y curl wget git apt-transport-https ca-certificates gnupg lsb-release

# --------------------------- 2. .NET 9 SDK ---------------------------
echo "[2/13] Ensuring .NET 9 SDK is installed..."
if ! command -v dotnet &>/dev/null || ! dotnet --list-sdks | grep -q "^9\."; then
  # Add Microsoft package repository
  wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
  sudo dpkg -i packages-microsoft-prod.deb
  rm packages-microsoft-prod.deb

  sudo apt update
  sudo apt install -y dotnet-sdk-9.0
fi
dotnet --version

# --------------------------- 3. Node.js and npm ---------------------------
echo "[3/13] Ensuring Node.js and npm are installed..."
if ! command -v node &>/dev/null || ! node --version | grep -q "^v20\."; then
  # Install Node.js 20.x LTS via NodeSource
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt install -y nodejs
fi
node --version
npm --version

# --------------------------- 4. Docker ---------------------------
echo "[4/13] Ensuring Docker is installed..."
if ! command -v docker &>/dev/null; then
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  sudo usermod -aG docker $USER
fi
sudo systemctl enable docker || true
sudo systemctl start docker || true

# --------------------------- 5. kubectl ---------------------------
echo "[5/13] Ensuring kubectl is installed..."
if ! command -v kubectl &>/dev/null; then
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl
fi

# --------------------------- 6. Minikube ---------------------------
echo "[6/13] Ensuring Minikube is installed..."
if ! command -v minikube &>/dev/null; then
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64
fi

echo "[7/13] Starting Minikube (if not already running)..."
if ! minikube status &>/dev/null; then
  minikube start --driver=docker --memory=12288 --cpus=6 --force
fi
kubectl config use-context minikube

# --------------------------- 8. Helm ---------------------------
echo "[8/13] Ensuring Helm is installed..."
if ! command -v helm &>/dev/null; then
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# --------------------------- 9. cert-manager ---------------------------
echo "[9/13] Installing/repairing cert-manager..."
helm repo add jetstack https://charts.jetstack.io || true
helm repo update

kubectl get namespace cert-manager &>/dev/null || kubectl create namespace cert-manager

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --set crds.enabled=true \
  --wait

kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=180s

# --------------------------- 10. ARC (Auto Reset) ---------------------------
echo "[10/13] Preparing Actions Runner Controller..."

# Auto-reset ARC if installed
if helm status actions-runner-controller -n actions-runner-system &>/dev/null; then
  echo "⚠ ARC already installed. Deleting existing release and namespace..."
  helm uninstall actions-runner-controller -n actions-runner-system || true
  kubectl delete namespace actions-runner-system || true
fi

kubectl get namespace actions-runner-system &>/dev/null || kubectl create namespace actions-runner-system

# Create GitHub token secret
kubectl create secret generic controller-manager \
  --namespace actions-runner-system \
  --from-literal=github_token="$GITHUB_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -
echo "✅ GitHub token secret created."

# Install ARC
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller || true
helm repo update

echo "[10.1/13] Installing ARC..."
helm upgrade --install actions-runner-controller actions-runner-controller/actions-runner-controller \
  --namespace actions-runner-system --wait

kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=actions-runner-controller -n actions-runner-system --timeout=180s || \
echo "⚠ ARC pods may not be fully ready yet. Check logs with: kubectl logs -n actions-runner-system -l app.kubernetes.io/name=actions-runner-controller"

# --------------------------- 11. Monitoring Tools ---------------------------
echo "[11/13] Installing htop (if missing)..."
sudo apt install -y htop

# --------------------------- 12. Verify Installations ---------------------------
echo "[12/13] Verifying installations..."
echo "  ✓ .NET version: $(dotnet --version)"
echo "  ✓ Node.js version: $(node --version)"
echo "  ✓ npm version: $(npm --version)"
echo "  ✓ Docker version: $(docker --version)"
echo "  ✓ kubectl version: $(kubectl version --client -o jsonpath='{.clientVersion.gitVersion}' 2>/dev/null || echo "unknown")"
echo "  ✓ Minikube version: $(minikube version --short)"
echo "  ✓ Helm version: $(helm version --short)"

# --------------------------- 13. Finished ---------------------------
echo "========================================="
echo "✅ Setup Complete!"
echo "========================================="
echo "Next Steps:"
echo "  • Apply RunnerDeployment YAML (e.g., runner.yaml)"
echo "  • kubectl get pods -n actions-runner-system"
echo "  • Run: newgrp docker (if 'docker command not found')"
echo "========================================="
