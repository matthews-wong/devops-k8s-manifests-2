# hardened-nginx-manifests

Plain Kubernetes manifests for a small static-content nginx frontend, written
the way I'd want to hand them to a teammate: pinned image, resource limits,
health probes, and a restrictive `securityContext` from the start rather than
bolted on later.

No Helm, no framework scaffolding - just YAML you can read top to bottom in a
couple of minutes, tied together with a single `kustomization.yaml`.

## What's here

- `manifests/namespace.yaml` - a dedicated namespace for the app
- `manifests/deployment.yaml` - the nginx workload
- `manifests/service.yaml` - a ClusterIP service in front of it
- `manifests/configmap.yaml` - the static page it serves
- `manifests/poddisruptionbudget.yaml` - a floor on availability during drains
- `manifests/networkpolicy.yaml` - default-deny ingress except on the app port
- `manifests/kustomization.yaml` - ties the above into one applyable set

## Usage

```sh
kubectl apply -k manifests/
```

## Design decisions

- **Image pinned by digest, not tag.** `nginxinc/nginx-unprivileged:1.27-alpine`
  already runs as a non-root user out of the box, so the digest pin buys
  supply-chain safety without fighting the image's own UID.
- **`readOnlyRootFilesystem: true` plus three `emptyDir` mounts.** nginx still
  needs to write to `/tmp`, `/var/cache/nginx`, and `/var/run` even when it
  isn't touching its own binaries or config - those are exactly the paths
  volumes are mounted over.
- **NetworkPolicy scopes ingress to the container port**, not to specific
  namespaces, since this manifest set doesn't know what else shares the
  cluster it's applied to; tighten the `from` selector per-environment.

## Validation

This repo has no live cluster to apply against, so manifests are checked
statically with [kubeconform](https://github.com/yannh/kubeconform) instead:

```sh
./scripts/validate.sh
```

The script downloads a pinned, checksum-verified kubeconform release into
`~/.cache` on first run and reuses it (or an already-installed `kubeconform`
on `PATH`) afterwards.
