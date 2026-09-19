# hardened-nginx-manifests

[![validate](https://github.com/matthews-wong/devops-k8s-manifests-2/actions/workflows/validate.yaml/badge.svg)](https://github.com/matthews-wong/devops-k8s-manifests-2/actions/workflows/validate.yaml)

Plain Kubernetes manifests for a small static-content nginx frontend, written
the way I'd want to hand them to a teammate: pinned image, resource limits,
health probes, and a restrictive `securityContext` from the start rather than
bolted on later.

No Helm, no framework scaffolding - just YAML you can read top to bottom in a
couple of minutes, tied together with a single `kustomization.yaml`.

## What's here

- `manifests/namespace.yaml` - a dedicated namespace for the app
- `manifests/serviceaccount.yaml` - a dedicated, non-token-mounting ServiceAccount
- `manifests/deployment.yaml` - the nginx workload
- `manifests/service.yaml` - a ClusterIP service in front of it
- `manifests/configmap.yaml` - the static page it serves
- `manifests/poddisruptionbudget.yaml` - a floor on availability during drains
- `manifests/networkpolicy.yaml` - default-deny ingress/egress except the app port and DNS
- `manifests/hpa.yaml` - scales replicas on CPU utilization
- `manifests/resourcequota.yaml` - namespace-wide compute and pod-count ceilings
- `manifests/limitrange.yaml` - per-container defaults and min/max bounds
- `manifests/kustomization.yaml` - ties the above into one applyable set
- `overlays/dev` - lower replica/HPA ceiling for local or scratch clusters
- `overlays/staging` - a mid-sized replica/HPA ceiling, still inside the base ResourceQuota
- `overlays/prod` - higher replica/HPA ceiling with a matching ResourceQuota

## Usage

```sh
kubectl apply -k manifests/         # base, as shipped
kubectl apply -k overlays/dev/      # single replica, HPA capped at 2
kubectl apply -k overlays/staging/  # 2 replicas, HPA capped at 4
kubectl apply -k overlays/prod/     # 3 replicas, HPA capped at 10, larger quota
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
  Egress is default-deny except DNS, since a static page server never needs
  to call out.
- **ServiceAccount token automount is disabled**, both on the account and
  the pod, since this workload never talks to the API server - one less
  credential sitting in every pod's filesystem.
- **Anti-affinity is `preferred`, not `required`.** A hard rule would refuse
  to schedule a second replica on a single-node dev/test cluster; the soft
  rule still asks the scheduler to spread when it can.
- **A 5s `preStop` sleep before nginx receives SIGTERM.** Without it, kubelet
  can terminate the container before kube-proxy has finished removing it
  from the Service's endpoints, dropping in-flight requests during a
  rollout or scale-down.
- **HPA min/max and the ResourceQuota agree with each other.** The quota is
  sized against the HPA's 6-replica ceiling plus rollout headroom, so
  autoscaling can't silently hit a quota wall it doesn't know about.
- **Overlays patch replicas/HPA/quota together, never one alone.** Bumping an
  overlay's HPA ceiling without also raising its ResourceQuota would just move
  the "silent quota wall" problem from the base into the overlay. `staging`
  only needs to patch replicas/HPA because its 4-replica ceiling still fits
  inside the base ResourceQuota; `prod` patches the quota too because its
  ceiling doesn't.

## Validation

This repo has no live cluster to apply against, so the base manifests and both
overlays are checked statically with
[kubeconform](https://github.com/yannh/kubeconform) instead:

```sh
./scripts/validate.sh
# or: make validate
```

The script downloads a pinned, checksum-verified kubeconform release into
`~/.cache` on first run and reuses it (or an already-installed `kubeconform`
on `PATH`) afterwards. It finishes by running
`scripts/check-overlay-floors.sh` (also `make check-floors`), which renders
all three overlays and fails if `dev`'s replica count or HPA bounds ever
exceed `staging`'s, or `staging`'s exceed `prod`'s. A GitHub Actions workflow
runs the same script on every push and pull request against `main`.

`make build`, `make build-dev`, and `make build-prod` print the rendered
manifests for the base and each overlay (requires `kustomize` on `PATH`) -
useful for eyeballing a patch before applying it.
