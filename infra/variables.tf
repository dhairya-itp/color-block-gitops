variable "region" {
  description = "AWS region. ap-south-1 is Mumbai."
  type        = string
  default     = "ap-south-1"
}

variable "owner" {
  description = "Owner tag on every resource. Some AWS orgs deny EC2 launches without it (use your work email)."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[a-z]+$", var.owner))
    error_message = "owner must be an email address."
  }
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

variable "argocd_allowed_cidrs" {
  description = "Who can reach the Argo CD UI load balancer. Narrow it to your IP (x.x.x.x/32) if you can."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "github_token" {
  description = "Fine-grained GitHub token for the deck's bridge: color-block-gitops only, Contents read/write, Checks read. Put it in terraform.tfvars (git-ignored), never in a committed file."
  type        = string
  sensitive   = true
}
