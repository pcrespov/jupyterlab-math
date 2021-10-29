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
	@echo Type "simcore-service-integrator --help"


config:
	docker-compose --file compose-code-server.yml config

up:
	docker-compose --file compose-code-server.yml up

down:
	docker-compose --file compose-code-server.yml down
