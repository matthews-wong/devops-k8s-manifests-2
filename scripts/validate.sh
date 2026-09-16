#!/usr/bin/env bash
# Validates the manifests in manifests/ both as loose YAML and as rendered by
# kustomize, against the upstream Kubernetes OpenAPI schemas via kubeconform.
# Downloads pinned releases of both tools into a local cache if they aren't
# already on PATH.
set -euo pipefail

KUBECONFORM_VERSION="0.6.7"
KUBECONFORM_SHA256="95f14e87aa28c09d5941f11bd024c1d02fdc0303ccaa23f61cef67bc92619d73"
KUBECONFORM_CACHE_DIR="${HOME}/.cache/kubeconform-${KUBECONFORM_VERSION}"
KUBECONFORM_BIN="${KUBECONFORM_CACHE_DIR}/kubeconform"

KUSTOMIZE_VERSION="5.4.3"
KUSTOMIZE_SHA256="3669470b454d865c8184d6bce78df05e977c9aea31c30df3c669317d43bcc7a7"
KUSTOMIZE_CACHE_DIR="${HOME}/.cache/kustomize-${KUSTOMIZE_VERSION}"
KUSTOMIZE_BIN="${KUSTOMIZE_CACHE_DIR}/kustomize"

if ! command -v kubeconform >/dev/null 2>&1 && [ ! -x "${KUBECONFORM_BIN}" ]; then
  mkdir -p "${KUBECONFORM_CACHE_DIR}"
  archive="$(mktemp)"
  curl -fsSL -o "${archive}" \
    "https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz"
  echo "${KUBECONFORM_SHA256}  ${archive}" | sha256sum -c -
  tar -xzf "${archive}" -C "${KUBECONFORM_CACHE_DIR}" kubeconform
  rm -f "${archive}"
fi

if ! command -v kustomize >/dev/null 2>&1 && [ ! -x "${KUSTOMIZE_BIN}" ]; then
  mkdir -p "${KUSTOMIZE_CACHE_DIR}"
  archive="$(mktemp)"
  curl -fsSL -o "${archive}" \
    "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz"
  echo "${KUSTOMIZE_SHA256}  ${archive}" | sha256sum -c -
  tar -xzf "${archive}" -C "${KUSTOMIZE_CACHE_DIR}" kustomize
  rm -f "${archive}"
fi

KUBECONFORM="$(command -v kubeconform || echo "${KUBECONFORM_BIN}")"
KUSTOMIZE="$(command -v kustomize || echo "${KUSTOMIZE_BIN}")"

echo "==> validating raw manifests"
"${KUBECONFORM}" -strict -summary -ignore-filename-pattern 'kustomization\.yaml$' manifests/*.yaml

echo "==> validating kustomize build output"
"${KUSTOMIZE}" build manifests/ | "${KUBECONFORM}" -strict -summary -
