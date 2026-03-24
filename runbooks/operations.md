# Operations Runbook

## On-call baseline

- Ownership: Platform team
- Coverage: 24x7 business-critical services, office-hour for tier-2
- Escalation: App owner -> Platform -> Infra/Security

## Deployment checks

1. Confirm CI green and image is signed.
2. Confirm staging health (error rate, latency, saturation).
3. Run promotion workflow with target `image_tag`.
4. Observe rollout steps and pause windows.

## One-click rollback

### GitOps rollback

- Revert the latest commit in `gitops/environments/<env>/`.
- Push commit and let Argo CD reconcile.

### Argo Rollouts rollback

```bash
kubectl argo rollouts undo rollout/sample-service -n sample-service
```

## Failure drills

- Registry unavailable
- Bad config rollout
- Probe failures

Each drill should verify recovery in under 5 minutes for production-critical services.
