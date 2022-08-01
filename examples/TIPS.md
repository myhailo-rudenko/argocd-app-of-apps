# 1. установить helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm


# 2. установить ingress-nginx
scp ingress-nginx-values.yml root@10.1.25.10:/opt/
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --values /opt/ingress-nginx-values.yml


# 3. установить kube-prometheus-stack:
scp ./prometheus-values.yml  root@10.1.25.10:/opt/
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus --namespace monitoring prometheus-community/kube-prometheus-stack --create-namespace --values /opt/prometheus-values.yml


# 4. настроить kube-proxy
metricsBindAddress: 0.0.0.0:10249
+ удалить kube-proxy pods (это их перезагрузит)


# 5. cert-manager для ingress-nginx
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.8.2 --create-namespace

# kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.2/cert-manager.crds.yaml

scp ca-cluster-issuer.yml root@10.1.25.10:/opt/
scp ca-cluster-issuer*.yml  root@10.1.25.10:/opt/
kubectl apply -f /opt/ca-cluster-issuer-prod.yml --namespace cert-manager
kubectl apply -f /opt/ca-cluster-issuer-staging.yml --namespace cert-manager

helm show values jetstack/cert-manager
helm show values ingress-nginx --repo https://kubernetes.github.io/ingress-nginx
helm show values prometheus-community/kube-prometheus-stack

helm uninstall cert-manager --namespace cert-manager

# Аннотации для ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    kubernetes.io/tls-acme: "true"
    cert-manager.io/cluster-issuer: letsencrypt-prod
>>!   или
    kubernetes.io/ingress.class: nginx
    kubernetes.io/tls-acme: "true"
    cert-manager.io/cluster-issuer: letsencrypt-staging

kubectl describe certificate nginx-ingress-admission --namespace ingress-nginx


# 6. OpenEBS
helm repo add openebs https://openebs.github.io/charts
helm repo update
helm install openebs openebs/openebs --namespace openebs --create-namespace


# 7. argocd
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install argo-cd bitnami/argo-cd --namespace argo-cd --create-namespace --values /opt/bitnami-argo-cd_values.yml
helm install argo-cd bitnami/argo-cd --values /opt/bitnami-argo-cd_values.yml

kubectl create namespace argo-cd
kubectl apply -n argo-cd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# Получить пароль
admin
echo "Password: $(kubectl -n argo-cd get secret argocd-secret -o jsonpath="{.data.clearPassword}" | base64 -d)"

# 8. NFS Storage
helm install nfs-storage nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
>     --set nfs.server=10.10.10.251 \
>     --set nfs.path=/mnt/nfsdir_client

helm install nfs-storage nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=10.10.10.251 \
    --set nfs.path=/srv

# 9. Gitea
helm install gitea gitea-charts/gitea --values gitea-values.yaml -n gitea --create-namespace
