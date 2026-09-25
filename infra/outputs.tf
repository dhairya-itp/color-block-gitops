output "configure_kubectl" {
  description = "Point kubectl (and the deck's bridge) at the cluster."
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}

output "argocd_password" {
  description = "Argo CD admin password (user: admin)."
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "argocd_ui" {
  value = "kubectl -n argocd port-forward svc/argocd-server 8443:443   # https://localhost:8443"
}

output "website" {
  value = "kubectl -n demo port-forward svc/color-block 8080:80   # http://localhost:8080"
}
