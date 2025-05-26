# 🐳 Local Kubernetes Stack with K3d

Production-like Kubernetes environment using [k3d](https://k3d.io/) + [K3s](https://k3s.io/) for local development.

**One script setup. Clean URLs. No port-forwarding needed.**

---

## ⛳️ What You Get

| Service        | Purpose                        | URL                             |
|----------------|--------------------------------|---------------------------------|
| **Keycloak**   | Identity & Access Management   | `http://keycloak.local:30080`   |
| **Grafana**    | Monitoring Dashboards          | `http://grafana.local:30080`    |
| **Prometheus** | Metrics Collection             | `http://prometheus.local:30080` |
| **Vault**      | Secrets Management             | `http://vault.local:30080`      |
| **MinIO**      | Object Storage (S3-compatible) | `http://minio.local:30080`      |
| **Kafka + UI** | Message Streaming & Management | `http://kafka-ui.local:30080`   |
| **Dashboard**  | Cluster Management             | `https://localhost:8443`        |

> **ℹ️ Dashboard Access Note**  
> The Kubernetes Dashboard runs on `https://localhost:8443` via port-forwarding instead of Ingress. This approach
> provides better security and token validation for local development. Use `./dashboard.sh` to manage port-forwarding
> easily (start, stop, open browser, get token).
---

## 🚀 Quick Start

```bash
# 1. Install everything
chmod +x install.sh && ./install.sh

# 2. Setup clean URLs  
chmod +x deploy-ingress.sh && ./deploy-ingress.sh

# 3. Access services
open http://keycloak.local:30080
```

**That's it!** All services accessible via clean URLs, no port-forwarding needed.

---

## ⚙️ Prerequisites

- **Docker Desktop** (running)
- **k3d** ≥ v5.0 – [Install](https://k3d.io/#installation)
- **kubectl** – [Install](https://kubernetes.io/docs/tasks/tools/)

---

## 🔧 Essential Commands

```bash
# Check everything is running
kubectl get pods -A

# View all services
kubectl get ingress -A


# Dashboard management
./dashboard.sh start    # Start Dashboard port-forward
./dashboard.sh open     # Open Dashboard in browser
./dashboard.sh token    # Get access token
./dashboard.sh status   # Check Dashboard status

# Cleanup
k3d cluster delete dev-cluster
```

---

## 📁 Key Files

```
k3d-stack/
├── install.sh              # Install Main installer
├── uninstall.sh            # Remove Main installer
├── dashboard.sh            # Manage the dashboard
├── deploy-ingress.sh       # Setup clean URLs
├── helm/                   # Service configurations
└── kube/                   # Cluster config
```

---

## 🔄 Development Workflow

1. **Start:** `./install.sh` → Select services to install
2. **Access:** `./deploy-ingress.sh` → Get clean URLs
3. **Develop:** Use supporting services (auth, monitoring, storage)
4. **Deploy:** Add your apps to the cluster (Exemples to add)
5. **Cleanup:** `k3d cluster delete dev-cluster` or `./uninstall.sh`

---

## 🚨 Quick Fixes

**Ingress not working?**

```bash
kubectl get svc -n ingress-nginx
grep "local" /etc/hosts
```

**Service down?**

```bash
kubectl logs -n <namespace> <pod-name>
kubectl describe pod <pod-name> -n <namespace>
```

---

**Ready to code? Run `./install.sh` and you're set ! **