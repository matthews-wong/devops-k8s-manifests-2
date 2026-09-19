.PHONY: validate build build-dev build-staging build-prod

validate:
	./scripts/validate.sh

build:
	kustomize build manifests/

build-dev:
	kustomize build overlays/dev/

build-staging:
	kustomize build overlays/staging/

build-prod:
	kustomize build overlays/prod/
