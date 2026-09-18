# Contributing

## Making a change

1. Edit the manifests under `manifests/` (the base) or `overlays/<env>/`
   (per-environment patches).
2. Run the validator:

   ```sh
   ./scripts/validate.sh
   ```

   It checks the raw manifests and every `kustomize build` output (base plus
   each overlay) against the upstream Kubernetes OpenAPI schemas via
   [kubeconform](https://github.com/yannh/kubeconform). The same script runs
   in CI on every push and pull request.
3. If you touch the design decisions in the README, keep that section in
   sync - it's meant to explain *why*, not just list files.

## Conventions

- One logical change per commit, [Conventional Commits](https://www.conventionalcommits.org/)
  style (`feat:`, `fix:`, `docs:`, `chore:`, ...).
- Every container keeps its resource requests/limits, probes, and
  `securityContext` hardening - see the README's design-decisions section
  before removing any of them.
- Pin what you add: image digests, not tags; GitHub Actions by commit SHA,
  not a moving version tag.
