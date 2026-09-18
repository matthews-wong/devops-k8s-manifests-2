.PHONY: validate build build-dev build-prod

validate:
	./scripts/validate.sh

build:
	kustomize build manifests/

build-dev:
	kustomize build overlays/dev/

build-prod:
	kustomize build overlays/prod/
