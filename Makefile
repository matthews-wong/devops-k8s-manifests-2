.PHONY: validate check-floors build build-dev build-staging build-prod

validate:
	./scripts/validate.sh

check-floors:
	./scripts/check-overlay-floors.sh

build:
	kustomize build manifests/

build-dev:
	kustomize build overlays/dev/

build-staging:
	kustomize build overlays/staging/

build-prod:
	kustomize build overlays/prod/
