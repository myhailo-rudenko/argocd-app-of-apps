# Скачать dependencies
helm dependency build argocd-app-of-apps/root-chart/
# Создать template
helm template -n argo-cd argocd-app-of-apps/root-chart/ > helm-template.yaml

# Добавить в Chart.yaml
dependencies:
- name: argo-cd
  version: 4.0.2
  repository: "https://charts.bitnami.com/bitnami"

# Добавить в values.yaml
global:
  storageClass: openebs-device
server:
  ingress:
    enabled: true
    hostname: argocd.k8s-c02.ubn24.de
    annotations:
      kubernetes.io/ingress.class: nginx
      kubernetes.io/tls-acme: 'true'
      cert-manager.io/cluster-issuer: letsencrypt-staging
      nginx.ingress.kubernetes.io/backend-protocol: HTTPS
      nginx.ingress.kubernetes.io/force-ssl-redirect: 'true'
      nginx.ingress.kubernetes.io/ssl-passthrough: 'true'
    tls: true

# Пример argo-cd
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argo-cd
  namespace: argo-cd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    chart: argo-cd
    repoURL: https://charts.bitnami.com/bitnami
    targetRevision: 4.0.2
    helm:
      values: |
        global:
          storageClass: openebs-device
        server:
          ingress:
            enabled: true
            hostname: argocd.k8s-c02.ubn24.de
            annotations:
              kubernetes.io/ingress.class: nginx
              kubernetes.io/tls-acme: 'true'
              cert-manager.io/cluster-issuer: letsencrypt-staging
              nginx.ingress.kubernetes.io/backend-protocol: HTTPS
              nginx.ingress.kubernetes.io/force-ssl-redirect: 'true'
              nginx.ingress.kubernetes.io/ssl-passthrough: 'true'
            tls: true
  destination:
    server: https://kubernetes.default.svc
    namespace: argo-cd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
