# Incident Response

## Severity guide

- SEV1: Revenue-critical outage, customer-facing major impact
- SEV2: Partial outage, major degradation
- SEV3: Minor degradation or internal-only impact

## Initial response (first 10 minutes)

1. Declare severity and incident commander.
2. Freeze non-essential deployments.
3. Gather timeline from CI/CD, Argo CD, and monitoring.
4. Decide rollback vs fix-forward.

## Data sources

- GitHub workflow run logs
- Argo CD app history
- Kubernetes events and pod logs
- DORA deployment events (`dora/events/*.json`)

## Postmortem requirements

- Root cause
- Detection gap
- Recovery timeline
- Preventive actions with owner and due date
