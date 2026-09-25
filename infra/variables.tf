variable "region" {
  description = "AWS region. ap-south-1 is Mumbai."
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  type    = string
  default = "scd"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version. Must be set: the node group needs it at plan time."
  type        = string
  default     = "1.36"
}

variable "node_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "node_count" {
  type    = number
  default = 2
}

variable "argocd_chart_version" {
  description = "argo-cd Helm chart version (https://artifacthub.io/packages/helm/argo/argo-cd)."
  type        = string
  default     = "10.9.2"
}
