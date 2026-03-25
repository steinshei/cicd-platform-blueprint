# Operations Runbook

## On-call baseline

- Ownership: Platform team
- Coverage: 24x7 business-critical services, office-hour for tier-2
- Escalation: App owner -> Platform -> Infra/Security

## Deployment policy

- Dev: auto promotion via `deploy(dev)` PR auto-merge.
- Staging/Prod: manual approval and manual merge are mandatory.
- Required checks on `main`:
  - `pipeline / validate-build-scan`
  - `security / semgrep`
  - `security / codeql (actions, none)`
  - `security / codeql (go, autobuild)`

## Deployment checks

1. Confirm CI is green and image signature/SBOM are available.
2. Confirm staging health (error rate, latency, saturation).
3. Run `promote` workflow with target `image_tag`.
4. Observe rollout weights and pause windows (5/20/50/100).
5. Ensure DORA event artifacts are uploaded in run summary.

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

Execution references:
- `docs/CLUSTER_PHASE2_PLAYBOOK.md`
- `docs/CLUSTER_PHASE2_COMMAND_CHECKLIST.md`
- `runbooks/drill-record-template.md`
## DORA weekly report

- Workflow: `dora-weekly-report`
- Output artifact: `dora-weekly-report-<run_id>`
- Report files:
  - `dora/reports/weekly-report.json`
  - `dora/reports/weekly-report.md`
