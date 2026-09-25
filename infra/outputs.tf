output "configure_kubectl" {
  description = "Point kubectl (and the deck's bridge) at the cluster."
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}

output "argocd_password" {
  description = "Argo CD admin password (user: admin)."
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "argocd_url" {
  description = "Argo CD UI on its NLB (DNS takes 2-3 min after the NLB is created). Self-signed cert: accept the warning."
  value       = "echo https://$(kubectl -n argocd get svc argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
}

output "website_url" {
  description = "The color-block website on its NLB."
  value       = "echo http://$(kubectl -n demo get svc color-block -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
}
