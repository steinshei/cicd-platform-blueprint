# Security Workflow Migration (Parallel Mode)

## Why Parallel Mode
Current branch protection likely requires existing check names from `security-sast`.
Directly replacing workflow can block merges if required check names change.

This rollout keeps old and new workflows running together first:
- Existing: `security-sast` (current required checks)
- New: `security-sast-platform` (from `platform-cicd@v1`)

## Rollout Steps
1. Merge this branch.
2. Run 3-5 PRs and verify both old/new security workflows are stable.
3. In branch protection, switch required checks to platform-based names.
4. Remove old `.github/workflows/security-sast.yaml` in a follow-up PR.

## Acceptance
- `security-sast-platform` is green on PR and main push.
- No false failure increase vs current `security-sast`.
- Required checks updated successfully without blocking merges.
