data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
  tags = {
    Project = "commit-to-production-demo"
    Owner   = var.owner
  }
}

# Public subnets only: nodes get public IPs and reach the EKS API, ECR and GitHub
# directly, so there is no NAT gateway to pay for. Fine for a one-day demo cluster.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = var.cluster_name
  cidr = "10.0.0.0/16"
  azs  = local.azs

  public_subnets          = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]
  map_public_ip_on_launch = true
  enable_nat_gateway      = false

  public_subnet_tags = { "kubernetes.io/role/elb" = 1 }
  tags               = local.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  addons = {
    vpc-cni                = { before_compute = true }
    eks-pod-identity-agent = { before_compute = true }
    kube-proxy             = {}
    coredns                = {}
  }

  # The module creates the node IAM role with the worker, CNI and ECR policies.
  eks_managed_node_groups = {
    demo = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = [var.node_instance_type]
      min_size       = var.node_count
      max_size       = var.node_count
      desired_size   = var.node_count
    }
  }

  tags = local.tags
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = "argocd"
  create_namespace = true
  wait             = true

  values = [yamlencode({
    configs = {
      cm = {
        # Check Git every 30s, with no random delay. The deck's bridge also asks for a refresh on each commit.
        "timeout.reconciliation"        = "30s"
        "timeout.reconciliation.jitter" = "0s"
      }
    }
  })]

  depends_on = [module.eks]
}

# The Application is defined once, in argocd/application.yaml, and installed through the argocd-apps chart.
locals {
  app = yamldecode(file("${path.module}/../argocd/application.yaml"))
}

resource "helm_release" "color_block_app" {
  name       = "color-block-app"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.5"
  namespace  = "argocd"

  values = [yamlencode({
    applications = {
      (local.app.metadata.name) = merge(local.app.spec, {
        namespace  = local.app.metadata.namespace
        finalizers = local.app.metadata.finalizers
      })
    }
  })]

  depends_on = [helm_release.argocd]
}
