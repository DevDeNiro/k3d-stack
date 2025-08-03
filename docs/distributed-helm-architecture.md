# Architecture Helm Distribuée avec Templates Centralisés

## Vue d'ensemble

Cette architecture permet de centraliser les templates Helm réutilisables dans `k3d-stack/charts/common-library` tout en gardant les configurations spécifiques dans chaque projet `votchain-*`.

## Structure

```
k3d-stack/
├── charts/
│   └── common-library/       # Templates centralisés (.tpl)
│       ├── Chart.yaml        # Library chart
│       └── templates/
│           ├── _deployment.tpl
│           ├── _service.tpl
│           ├── _ingress.tpl
│           └── _helpers.tpl
│
votchain-backend/
├── helm/
│   ├── Chart.yaml           # Référence common-library via Git URL
│   ├── values.yaml          # Configuration spécifique au backend
│   └── templates/
│       ├── deployment.yaml  # {{- include "common-library.deployment" . -}}
│       └── service.yaml     # {{- include "common-library.service" . -}}
```

## Avantages

### ✅ **Réduction du Boilerplate**
- Chaque projet a seulement 1-2 lignes par template
- Les templates complexes sont centralisés dans `common-library`
- Pas de duplication de code entre projets

### ✅ **Maintenance Simplifiée**  
- Un seul endroit pour mettre à jour les templates Kubernetes
- Les projets héritent automatiquement des améliorations
- Évite les erreurs de copier-coller

### ✅ **Configurations Décentralisées**
- Chaque projet garde sa configuration spécifique (`values.yaml`)
- Pas de centralisation artificielle des configs métier
- Autonomie des équipes sur leurs services

### ✅ **CI/CD Simplifié**
- Helm peut résoudre les dépendances Git automatiquement
- Pas besoin de monorepo ou de registry Helm complexe
- Cache des dépendances par Helm

## Comment référencer common-library

### Option 1: Git URL (Recommandée pour multi-repo)
```yaml
# Chart.yaml
dependencies:
  - name: common-library
    version: "1.0.0"
    repository: "git+https://gitlab.com/your-org/k3d-stack@charts/common-library"
```

### Option 2: Path local (Pour développement local)
```yaml
# Chart.yaml  
dependencies:
  - name: common-library
    version: "1.0.0"
    repository: "file://../../k3d-stack/charts/common-library"
```

## CI/CD Pipeline

### Dans chaque projet votchain-*
```yaml
helm_lint:
  stage: test
  script:
    - helm dep update ./helm  # Télécharge common-library
    - helm lint ./helm

deploy:
  stage: deploy
  script:
    - helm dep update ./helm
    - helm upgrade --install ${CI_COMMIT_REF_SLUG} ./helm
      --set global.environment=${CI_COMMIT_REF_SLUG}
      --set image.tag=${CI_COMMIT_SHA}
```

### Dans k3d-stack (infrastructure)
```yaml
deploy_infrastructure:
  script:
    - helm upgrade --install postgres ./charts/postgresql
    - helm upgrade --install ingress-nginx ./charts/ingress-nginx
```

## Terraform vs Helm

### **Helm est suffisant pour :**
- Déploiement d'applications sur Kubernetes existant
- Gestion des services, deployments, configmaps
- Environnements éphémères (feature branches)

### **Terraform serait nécessaire pour :**
- Provisioning du cluster EKS sur AWS
- Configuration IAM, VPC, security groups
- Ressources AWS en dehors de Kubernetes

### **Notre stack actuelle :**
- **Helm** : Applications et services (suffisant pour k3d local + EC2 simple)
- **Terraform** : Pas nécessaire pour commencer, ajout possible plus tard

## Exemple concret

### Template dans common-library
```yaml
# k3d-stack/charts/common-library/templates/_deployment.tpl
{{- define "common-library.deployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "common-library.fullname" . }}
  # ... template complexe centralisé
{{- end -}}
```

### Utilisation dans projet
```yaml
# votchain-backend/helm/templates/deployment.yaml
{{- include "common-library.deployment" . -}}
```

### Configuration spécifique
```yaml  
# votchain-backend/helm/values.yaml
image:
  repository: "votchain-backend"
  tag: "latest"
  
env:
  NODE_ENV: "production"
  PORT: "3333"
```

## Migration depuis l'existant

1. **Garder common-library dans k3d-stack**
2. **Simplifier les templates de chaque projet** : 1 ligne par template
3. **Nettoyer les Chart.yaml** : pointer vers common-library
4. **Tester localement** : `helm template` et `helm install`
5. **Mettre à jour les CI/CD** : ajouter `helm dep update`

Cette approche combine le meilleur des deux mondes : templates centralisés pour éviter le boilerplate, configurations décentralisées pour l'autonomie des projets.
