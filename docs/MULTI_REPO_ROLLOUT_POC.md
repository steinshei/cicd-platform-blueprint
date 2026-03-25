# Multi-Repo Rollout PoC

## Goal
Validate a multi-repo CI/CD model where service repos use a thin entry workflow and call a shared reusable workflow from a platform repository.

## What This Branch Adds
- `.github/workflows/platform-ci-poc.yaml`
  - Manual trigger (`workflow_dispatch`)
  - Calls reusable workflow by repository reference:
    - `uses: steinshei/cicd-platform-blueprint/.github/workflows/reusable-ci.yml@main`

## Why This Is Safe
- Does not replace existing `ci-main` or `security-sast`
- No automatic triggers on push/PR
- Only runs when manually started in Actions UI

## How To Test In This Repo
1. Push this branch and open PR to `main`.
2. In GitHub Actions, run `platform-ci-poc` manually.
3. Use defaults (`sample-service`) first.
4. Verify jobs pass: build, test, scan, signing, attestation.

## Standard Multi-Repo Migration Pattern
1. Create org-level platform repo (for example `org/platform-cicd`).
2. Move shared reusable workflows there and version by tags (`v1`, `v1.1`).
3. In each service repo, keep only thin entry workflow:
   - `uses: org/platform-cicd/.github/workflows/reusable-ci.yml@v1`
4. Enforce org rulesets and required checks uniformly.
5. Roll out gradually (3-5 repos first), then scale.

## Next Step After PoC
Replace PoC `uses:` target with real platform repo and pinned tag.
