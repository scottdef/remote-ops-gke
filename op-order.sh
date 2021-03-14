gcloud init
terraform apply
./post-install.sh
source .envrc # if you have direnv, skip this

kubectl apply -f k8s/helm-tiller-rbac.yml
helm init --service-account tiller --history-max 200

kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/master/deploy/manifests/00-crds.yaml --validate=false
helm repo add jetstack https://charts.jetstack.io && helm repo update
# kubectl label namespace kube-system certmanager.k8s.io/disable-validation=
helm install jetstack/cert-manager --name cert-manager --values helm/cert-manager.yaml --namespace kube-system

kubectl apply -f k8s/cert-manager-issuers.yaml

# Create a zone first (not idempotent)
gcloud dns managed-zones create maelvls --description "My DNS zone" --dns-name=maelvls.dev
# Create a service account for managing the DNS records for external-dns
gcloud iam service-accounts create external-dns --display-name "For external-dns"
gcloud projects add-iam-policy-binding august-period-234610 --role='roles/dns.admin' --member='serviceAccount:dns-exporter@august-period-234610.iam.gserviceaccount.com'
gcloud iam service-accounts keys create credentials.json --iam-account dns-exporter@august-period-234610.iam.gserviceaccount.com
kubectl create secret generic external-dns --from-file=credentials.json=credentials.json
helm install --name external-dns stable/external-dns --values helm/external-dns.yaml

helm install --name traefik stable/traefik --values helm/traefik.yaml --namespace kube-system

helm install --name kubernetes-dashboard stable/kubernetes-dashboard --values helm/kubernetes-dashboard.yaml --namespace kube-system

helm install --name operator stable/prometheus-operator --namespace kube-system --values helm/operator.yaml
kubectl apply -f k8s/grafana-dashboards.yaml

git clone https://github.com/arthur-c/ansible-awx-helm-chart
helm dependency update ./ansible-awx-helm-chart/awx
helm install --name awx ./ansible-awx-helm-chart/awx --namespace awx --values helm/awx.yaml