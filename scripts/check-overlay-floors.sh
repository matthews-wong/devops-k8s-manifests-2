#!/usr/bin/env bash
# Asserts that overlays/dev <= overlays/staging <= overlays/prod on Deployment
# replicas and HPA min/maxReplicas, so a patch that raises one environment's
# ceiling below another's is caught before it reaches a cluster.
set -euo pipefail

KUSTOMIZE="$(command -v kustomize || echo "${HOME}/.cache/kustomize-5.4.3/kustomize")"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "${WORKDIR}"' EXIT

for overlay in dev staging prod; do
  "${KUSTOMIZE}" build "overlays/${overlay}" > "${WORKDIR}/${overlay}.yaml"
done

WORKDIR="${WORKDIR}" python3 - <<'PY'
import os
import sys

import yaml

ENVS = ["dev", "staging", "prod"]
workdir = os.environ["WORKDIR"]
readings = {}

for env in ENVS:
    replicas = min_replicas = max_replicas = None
    with open(os.path.join(workdir, f"{env}.yaml")) as f:
        for doc in yaml.safe_load_all(f):
            if doc is None:
                continue
            kind = doc.get("kind")
            if kind == "Deployment":
                replicas = doc["spec"]["replicas"]
            elif kind == "HorizontalPodAutoscaler":
                min_replicas = doc["spec"]["minReplicas"]
                max_replicas = doc["spec"]["maxReplicas"]
    readings[env] = (replicas, min_replicas, max_replicas)
    print(f"{env}: replicas={replicas} hpa=[{min_replicas},{max_replicas}]")

for lo, hi in zip(ENVS, ENVS[1:]):
    for field, idx in (("replicas", 0), ("hpa.minReplicas", 1), ("hpa.maxReplicas", 2)):
        if readings[lo][idx] > readings[hi][idx]:
            sys.exit(
                f"FAIL: {lo}.{field}={readings[lo][idx]} exceeds "
                f"{hi}.{field}={readings[hi][idx]}"
            )

print("OK: dev <= staging <= prod on replicas and HPA bounds")
PY
