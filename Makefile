


export VCS_URL    := $(shell git config --get remote.origin.url || echo unversioned)
export VCS_REF    := $(shell git rev-parse --short HEAD || echo unversioned)
export VCS_STATUS := $(if $(shell git status -s || echo unversioned),'modified/untracked','clean')
export BUILD_DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")


export VERSION  ?= $(shell cat VERSION)


export USER :=$(shell id -un)
export SUID :=$(shell id -u)
export SUID :=$(shell id -g)



devenv: ## builds dev environment installing simcore-service-integrator tool
	python3 -m venv .venv
	.venv/bin/pip install -U pip wheel setuptools
	.venv/bin/pip install -e ../osparc-simcore/packages/models-library
	.venv/bin/pip install -e ../osparc-simcore/packages/service-integration
	@echo Type "simcore-service-integrator --help"



up:
	docker-compose --file compose-code-server.yml up

down:
	docker-compose --file compose-code-server.yml down
