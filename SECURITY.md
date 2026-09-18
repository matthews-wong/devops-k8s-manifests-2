# Security policy

This repository is a set of static Kubernetes manifests - there's no running
service or endpoint to attack directly, but a manifest bug (a dropped
`securityContext`, an overly broad `NetworkPolicy`, an unpinned image) is
still a real weakness for anyone who applies it as-is.

## Reporting a vulnerability

If you find a manifest, script, or CI configuration in this repo that
undermines the hardening it documents (privilege escalation, a widened
NetworkPolicy, a mutable image tag, a leaked credential), please open a
private [security advisory](../../security/advisories/new) instead of a
public issue. Expect an initial response within a few days.

## Scope

- `manifests/` and `overlays/` - the Kubernetes objects themselves
- `scripts/validate.sh` and `.github/workflows/` - anything that runs in CI

Supported: the `main` branch only.
