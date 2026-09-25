# The deck namespace and the bridge's Secret. Argo CD deploys everything else in deck/.
# The token and presenter key end up in terraform.tfstate: keep that file private.
resource "kubernetes_namespace_v1" "deck" {
  metadata {
    name = "deck"
  }

  depends_on = [module.eks]
}

resource "random_password" "demo_key" {
  length  = 32
  special = false
}

resource "kubernetes_secret_v1" "deck" {
  metadata {
    name      = "deck-secrets"
    namespace = kubernetes_namespace_v1.deck.metadata[0].name
  }

  data = {
    GITHUB_TOKEN = var.github_token
    DEMO_KEY     = random_password.demo_key.result
  }
}
