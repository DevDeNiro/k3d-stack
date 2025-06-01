#!/bin/bash

### Script to deploy Ingress for currently deployed services ###

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Configuring Ingress for deployed services...${NC}"

# Check if Ingress Controller is installed
if ! kubectl get deployment ingress-nginx-controller -n ingress-nginx >/dev/null 2>&1; then
    echo -e "${RED}Error: Ingress Controller not found. Install it first with the main script.${NC}"
    exit 1
fi

# Function to deploy an Ingress if the namespace exists
deploy_ingress_if_namespace_exists() {
    local namespace=$1
    local service_name=$2
    local host=$3
    local port=$4
    local ingress_name="${service_name}-ingress"
    local additional_annotations=$5

    if kubectl get namespace "$namespace" >/dev/null 2>&1; then
        echo -e "${YELLOW}Deploying Ingress for $service_name ($host)...${NC}"

        # Check if service exists
        if kubectl get service "$service_name" -n "$namespace" >/dev/null 2>&1; then
            kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $ingress_name
  namespace: $namespace
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    $additional_annotations
spec:
  ingressClassName: nginx
  rules:
  - host: $host
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: $service_name
            port:
              number: $port
EOF
            echo -e "${GREEN}✓ Ingress $ingress_name created${NC}"
        else
            echo -e "${YELLOW}⚠ Service $service_name not found in $namespace${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Namespace $namespace not found, skipping $service_name${NC}"
    fi
}

# Function for Vault (HTTP API)
deploy_vault_ingress() {
    if kubectl get namespace vault >/dev/null 2>&1; then
        echo -e "${YELLOW}Deploying Ingress for Vault...${NC}"

        if kubectl get service vault -n vault >/dev/null 2>&1; then
            kubectl apply -f kube/vault-ingress.yaml
            echo -e "${GREEN}✓ Ingress vault-ingress created${NC}"
        else
            echo -e "${YELLOW}⚠ Vault service not found in vault namespace${NC}"
        fi
    fi
}

# Deploy Kafka UI Ingress if it exists
deploy_kafka_ui_ingress() {
    if kubectl get namespace messaging >/dev/null 2>&1; then
        if kubectl get deployment kafka-ui -n messaging >/dev/null 2>&1; then
            echo -e "${YELLOW}Deploying Ingress for existing Kafka UI...${NC}"

            kubectl apply -f kube/kafka-ui-ingress.yaml
            echo -e "${GREEN}✓ Ingress kafka-ui-ingress created${NC}"
            return 0
        fi
    fi
    return 1
}

deploy_kafka_ui() {
    if kubectl get namespace messaging >/dev/null 2>&1; then
        # Check if Kafka UI is already installed
        if kubectl get deployment kafka-ui -n messaging >/dev/null 2>&1; then
            echo -e "${GREEN}Kafka UI already installed, creating Ingress only${NC}"
            deploy_kafka_ui_ingress
            return 0
        fi

        echo -e "${YELLOW}Deploying Kafka UI for cluster visualization...${NC}"

        # Check if Kafka exists
        if kubectl get service kafka -n messaging >/dev/null 2>&1; then
            # Deploy Kafka UI
            kubectl apply -f kube/kafka-ui.yaml
            # Wait for deployment
            echo -e "${YELLOW}Waiting for Kafka UI to be ready...${NC}"
            kubectl wait --for=condition=available deployment/kafka-ui -n messaging --timeout=120s || true

            # Create Ingress
            deploy_kafka_ui_ingress

            echo -e "${GREEN}✓ Kafka UI deployed successfully${NC}"
        else
            echo -e "${YELLOW}⚠ Kafka service not found in messaging namespace${NC}"
        fi
    fi
}

# Function to prompt for yes/no confirmation
confirm() {
    local prompt="$1"
    local default="$2"

    if [ "$default" = "Y" ]; then
        local options="[Y/n]"
    else
        local options="[y/N]"
    fi

    read -r -p "$prompt $options: " answer

    if [ -z "$answer" ]; then
        answer="$default"
    fi

    if [[ "$answer" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

deploy_ingress_if_namespace_exists "security" "keycloak" "keycloak.local" 80
deploy_ingress_if_namespace_exists "monitoring" "grafana" "grafana.local" 80
deploy_ingress_if_namespace_exists "monitoring" "prometheus-server" "prometheus.local" 80
deploy_ingress_if_namespace_exists "monitoring" "alertmanager" "alertmanager.local" 9093
deploy_ingress_if_namespace_exists "storage" "minio-console" "minio.local" 9001
deploy_ingress_if_namespace_exists "logging" "kibana-kibana" "kibana.local" 5601

# Deploy Vault Ingress
deploy_vault_ingress

# Deploy Kafka UI Ingress (automatically if already installed, or ask to install)
if ! deploy_kafka_ui_ingress; then
    # Kafka UI not found, ask if user wants to install it
    if kubectl get namespace messaging >/dev/null 2>&1 && kubectl get service kafka -n messaging >/dev/null 2>&1; then
        if confirm "Kafka found but no Kafka UI. Deploy Kafka UI for cluster visualization?" "Y"; then
            deploy_kafka_ui
        else
            echo -e "${YELLOW}Kafka UI deployment skipped${NC}"
        fi
    fi
fi

echo -e "\n${GREEN}Ingress configuration completed!${NC}"

# Configure local hosts if not already done
echo -e "\n${YELLOW}Configuring local hosts...${NC}"
HOSTS_FILE="/etc/hosts"
DOMAINS=(
    "keycloak.local"
    "grafana.local"
    "prometheus.local"
    "alertmanager.local"
    "minio.local"
    "kibana.local"
    "vault.local"
    "kafka-ui.local"
 )

for domain in "${DOMAINS[@]}"; do
    if ! grep -q "127.0.0.1.*$domain" "$HOSTS_FILE"; then
        echo -e "${YELLOW}Adding $domain to hosts file${NC}"
        echo "127.0.0.1 $domain" | sudo tee -a "$HOSTS_FILE" > /dev/null
    fi
done

echo -e "\n${GREEN}=== Services accessible via Ingress ===${NC}"

# Detect Ingress Controller service type
SERVICE_TYPE=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.type}')

if [ "$SERVICE_TYPE" = "LoadBalancer" ]; then
    echo -e "${GREEN}Keycloak:${NC} http://keycloak.local"
    echo -e "${GREEN}Grafana:${NC} http://grafana.local"
    echo -e "${GREEN}Prometheus:${NC} http://prometheus.local"
    echo -e "${GREEN}AlertManager:${NC} http://alertmanager.local"
    echo -e "${GREEN}MinIO Console:${NC} http://minio.local"
    echo -e "${GREEN}Vault:${NC} http://vault.local"
    echo -e "${GREEN}Kibana:${NC} http://kibana.local"
    echo -e "${GREEN}Kafka UI:${NC} http://kafka-ui.local"
    echo -e "\n${YELLOW}LoadBalancer mode detected - using standard ports (80/443)${NC}"
else
    echo -e "${GREEN}Keycloak:${NC} http://keycloak.local:30080"
    echo -e "${GREEN}Grafana:${NC} http://grafana.local:30080"
    echo -e "${GREEN}Prometheus:${NC} http://prometheus.local:30080"
    echo -e "${GREEN}AlertManager:${NC} http://alertmanager.local:30080"
    echo -e "${GREEN}MinIO Console:${NC} http://minio.local:30080"
    echo -e "${GREEN}Vault:${NC} http://vault.local:30080"
    echo -e "${GREEN}Kibana:${NC} http://kibana.local:30080"
    echo -e "${GREEN}Kafka UI:${NC} http://kafka-ui.local:30080"
    echo -e "\n${YELLOW}NodePort mode detected - using ports 30080 (HTTP) and 30443 (HTTPS)${NC}"
    echo -e "${YELLOW}To switch to LoadBalancer mode, run: ./switch-to-loadbalancer.sh${NC}"
fi

echo -e "\n${YELLOW}Check Ingress Controller status:${NC}"
kubectl get svc -n ingress-nginx ingress-nginx-controller