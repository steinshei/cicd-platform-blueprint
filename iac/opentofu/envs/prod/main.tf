module "github_oidc" {
  source     = "../../modules/github_oidc"
  repository = "your-org/your-repo"
}

module "k8s_cluster" {
  source       = "../../modules/k8s_cluster"
  cluster_name = "platform-prod"
}
