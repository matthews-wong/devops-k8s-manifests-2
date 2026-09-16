# hardened-nginx-manifests

Plain Kubernetes manifests for a small static-content nginx frontend, written
the way I'd want to hand them to a teammate: pinned image, resource limits,
health probes, and a restrictive `securityContext` from the start rather than
bolted on later.

No Helm, no Kustomize base yet, no framework scaffolding - just YAML you can
read top to bottom in a couple of minutes.

## What's here

- `manifests/namespace.yaml` - a dedicated namespace for the app
- `manifests/deployment.yaml` - the nginx workload
- more to follow as the manifest set grows

## Usage

```sh
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/ -n hardened-nginx
```

## Validation

This repo has no live cluster to apply against, so manifests are checked
statically instead. See the validation section below as the tooling lands.
