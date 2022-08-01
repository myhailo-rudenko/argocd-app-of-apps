helm dependency build k8s-c02-chart/
helm dependency build eks-c01-chart/

helm template -n argo-cd k8s-c02-chart/ > k8s-c02-template.yaml
helm template -n argo-cd eks-c01-chart/ > eks-c01-template.yaml
