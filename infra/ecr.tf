# Where the deck image lives. Nodes can already pull from ECR (their role has ECR read-only).
resource "aws_ecr_repository" "deck" {
  name                 = "${var.cluster_name}-deck"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # so terraform destroy also removes the pushed images

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags
}
