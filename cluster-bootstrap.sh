#!/bin/bash
set -euo pipefail

# Addons argument parsing
ADDONS=${1:-}

# Check if argo addon is requested
if [[ "$ADDONS" == "argo" ]]; then
    # Install Argo CD
    echo "Installing Argo CD via Helm..."
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    helm install argo-cd argo/argo-cd --namespace argocd --create-namespace \
        -f addons/argo-cd/values.yaml --wait

    echo "Argo CD installed. Auto-logging in using admin secret..."
    export ARGOCD_SERVER="argo-cd-argocd-server:443"
    export ARGOCD_OPTS="--insecure"
    ARGOCD_ADMIN_PASSWORD=$(kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    argocd login --username admin --password $ARGOCD_ADMIN_PASSWORD --grpc-web --insecure

    echo "Applying App of Apps manifest..."
    kubectl apply -f clusters/local-k3d.yaml
else
    echo "Please specify --addons argo to install Argo CD"
fi
