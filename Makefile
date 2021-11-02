SHELL=bash

# repo specifics
export VCS_URL    := $(shell git config --get remote.origin.url || echo unversioned)
export VCS_REF    := $(shell git rev-parse --short HEAD || echo unversioned)
export VCS_STATUS := $(if $(shell git status -s || echo unversioned),'modified/untracked','clean')
export BUILD_DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

export VERSION  ?= $(shell cat VERSION)

# host specific
export USER :=$(shell id -un)

# osparc specific (simulation)
OSPARC_GLOBAL_EXCHANGE_VOLUME := $(CURDIR)/_osparcdata
PROJECT_ID := 392b50fa
NODE_ID := f0b9a2e7

OSPARC_APPDATA_VOLUME := ${OSPARC_GLOBAL_EXCHANGE_VOLUME}/${PROJECT_ID}/${NODE_ID}
$(shell mkdir -p ${OSPARC_APPDATA_VOLUME}/{config,inputs,outputs})


export OSPARC_APPDATA_CONFIG_VOLUME  := ${OSPARC_APPDATA_VOLUME}/config
export OSPARC_APPDATA_INPUTS_VOLUME  := ${OSPARC_APPDATA_VOLUME}/inputs
export OSPARC_APPDATA_OUTPUTS_VOLUME := ${OSPARC_APPDATA_VOLUME}/outputs


# user-service specific config
export SC_USER_NAME  := $(shell id -un)
export INPUT_FOLDER  := /config/.osparc/exchange/inputs
export OUTPUT_FOLDER := /config/.osparc/exchange/outputs

export PUID :=$(shell id -u)
export PGID :=$(shell id -g)



.PHONY: info devenv config up down

info:
	ls -la ${OSPARC_APPDATA_VOLUME}

devenv: ## builds dev environment installing simcore-service-integrator tool
	python3 -m venv .venv
	.venv/bin/pip install -U pip wheel setuptools
	.venv/bin/pip install -e ../osparc-simcore/packages/models-library
	.venv/bin/pip install -e ../osparc-simcore/packages/service-integration
	@echo Type "simcore-service-integrator --help" or "oint --help"


config:
	docker-compose --file compose-code-server.yml config

up:
	docker-compose --file compose-code-server.yml up

down:
	docker-compose --file compose-code-server.yml down


.PHONY: build inspect

export DOCKER_IMAGE_NAME := code-server
export DOCKER_IMAGE_TAG := $(VERSION)

build:
	# show config
	docker-compose -f docker-compose-meta.yml -f docker-compose-build.yml config
	# build
	docker-compose -f docker-compose-meta.yml -f docker-compose-build.yml build
	# inspect
	docker image inspect local/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} | jq

inspect:
	docker image inspect local/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} | jq

inspect-id:
	docker image inspect local/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} | jq '.[] | {id: .Id, tags:.RepoTags, digests: .RepoDigests} '

inspect-labels:
	docker image inspect local/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} | jq '.[] | .Config.Labels'


# DOCKER REGISTRY --------------------------------------

export DOCKER_REGISTRY := registry:5000
DOCKER_IMAGE_PUBLISHED_NAME := simcore/services/dynamic/${DOCKER_IMAGE_NAME}

publish:
	# publishing to ${DOCKER_REGISTRY}
	docker tag \
		local/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} \
		${DOCKER_REGISTRY}/${DOCKER_IMAGE_PUBLISHED_NAME}:${DOCKER_IMAGE_TAG}
	docker push \
		${DOCKER_REGISTRY}/${DOCKER_IMAGE_PUBLISHED_NAME}:${DOCKER_IMAGE_TAG}


define repo-digest ?=
$(shell docker image inspect ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} | jq -r '.[0].RepoDigests[0] | sub(".+@";"")')
endef

.PHONY: info digest delete
repo-info: ## SEE https://docs.docker.com/registry/spec/api/#detail
	# ping API
	curl --silent $(DOCKER_REGISTRY)/v2
	# list all
	curl --silent $(DOCKER_REGISTRY)/v2/_catalog | jq '.repositories'
	# simplified manifest
	curl --silent $(DOCKER_REGISTRY)/v2/$(DOCKER_IMAGE_PUBLISHED_NAME)/manifests/$(DOCKER_IMAGE_TAG) | jq 'del(.fsLayers) | del(.history)'
	# tags $(DOCKER_IMAGE_PUBLISHED_NAME)
	curl --silent $(DOCKER_REGISTRY)/v2/$(DOCKER_IMAGE_PUBLISHED_NAME)/tags/list | jq
	# repo-digest
	@echo $(repo-digest)

manifest:
	# NOTE: the Docker content digest in this header is NOT the reference recessary for deletion
	@curl -ISs $(DOCKER_REGISTRY)/v2/$(DOCKER_IMAGE_PUBLISHED_NAME)/manifests/$(DOCKER_IMAGE_TAG)

.PHONY: delete
repo-delete:
	curl --silent -X DELETE $(DOCKER_REGISTRY)/v2/$(DOCKER_IMAGE_PUBLISHED_NAME)/manifests/$(repo-digest)
