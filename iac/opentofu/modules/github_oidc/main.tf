variable "repository" {
  type = string
}

output "oidc_subject" {
  value = "repo:${var.repository}:ref:refs/heads/main"
}
