# OpenTofu Skeleton

This folder defines infra and CI identity building blocks.

## Modules

- `modules/github_oidc`: configures GitHub OIDC trust
- `modules/k8s_cluster`: cluster-level platform components

## Environments

- `envs/dev`
- `envs/staging`
- `envs/prod`

Each environment should wire remote state, provider auth, and module inputs.
