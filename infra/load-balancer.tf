# AWS Load Balancer Controller: turns Services of type LoadBalancer into Network Load Balancers.
module "lb_controller_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name                            = "${var.cluster_name}-aws-lb-controller"
  attach_aws_lb_controller_policy = true

  associations = {
    this = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }

  tags = local.tags
}

resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "3.5.0"
  namespace  = "kube-system"
  wait       = true

  values = [yamlencode({
    clusterName = module.eks.cluster_name
    region      = var.region
    vpcId       = module.vpc.vpc_id
    serviceAccount = {
      create = true
      name   = "aws-load-balancer-controller"
    }
    # Every load balancer, target group and security group it creates gets these tags.
    defaultTags = local.tags
  })]

  depends_on = [module.eks, module.lb_controller_pod_identity]
}

# NLBs belong to the controller, not to Terraform. On destroy, delete the Services that own
# them while the controller is still running, or the leftover NLBs block deleting the VPC.
resource "terraform_data" "delete_load_balancers" {
  input = {
    cluster = module.eks.cluster_name
    region  = var.region
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      export KUBECONFIG="$(mktemp)"
      trap 'rm -f "$KUBECONFIG"' EXIT
      aws eks update-kubeconfig --name ${self.input.cluster} --region ${self.input.region} >/dev/null
      kubectl -n argocd delete application color-block deck --ignore-not-found --wait --timeout=5m
      kubectl -n argocd delete service argocd-server --ignore-not-found --wait --timeout=5m
    EOT
  }

  depends_on = [helm_release.aws_lb_controller, helm_release.argocd, helm_release.color_block_app]
}
