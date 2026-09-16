#!/usr/bin/env bash
# Validates every manifest in manifests/ against the upstream Kubernetes
# OpenAPI schemas using kubeconform. Downloads a pinned kubeconform release
# into a local cache if it isn't already on PATH.
set -euo pipefail

KUBECONFORM_VERSION="0.6.7"
KUBECONFORM_SHA256="95f14e87aa28c09d5941f11bd024c1d02fdc0303ccaa23f61cef67bc92619d73"
CACHE_DIR="${HOME}/.cache/kubeconform-${KUBECONFORM_VERSION}"
BIN="${CACHE_DIR}/kubeconform"

if ! command -v kubeconform >/dev/null 2>&1 && [ ! -x "${BIN}" ]; then
  mkdir -p "${CACHE_DIR}"
  archive="$(mktemp)"
  curl -fsSL -o "${archive}" \
    "https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz"
  echo "${KUBECONFORM_SHA256}  ${archive}" | sha256sum -c -
  tar -xzf "${archive}" -C "${CACHE_DIR}" kubeconform
  rm -f "${archive}"
fi

KUBECONFORM="$(command -v kubeconform || echo "${BIN}")"

"${KUBECONFORM}" -strict -summary manifests/*.yaml
