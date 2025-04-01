CURRENT_DIR := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
CURRENT_DIRNAME := $(notdir $(abspath $(dir $(lastword $(MAKEFILE_LIST)))))

PROJECT_PREFIX ?= docker_maker
DETACH ?= 0
RUN_MODE := $(if $(filter 0,$(DETACH)),-it,-d)
USER := $(shell whoami)
HOSTNAME := $(shell hostname)
UID := $(shell id -u)
GID := $(shell id -g)
DOCKER_GID := $(shell getent group docker | cut -d: -f3)
IMAGE_NAME := $(PROJECT_PREFIX):$(USER)
CONTAINER_NAME := $(PROJECT_PREFIX)_$(USER)
VOLUME_NAME := $(PROJECT_PREFIX)_$(USER)_volume

DOCKER_HOSTNAME := $(PROJECT_PREFIX)_$(USER)
DOCKER_RUN_PREFIX := /var/run
DOCKER_DATA_ROOT_PREFIX := /var/lib
DOCKER_SOCKET_FILE := $(DOCKER_RUN_PREFIX)/$(DOCKER_HOSTNAME).sock
DOCKER_SOCKET := unix://$(DOCKER_SOCKET_FILE)
DOCKER_DATA_ROOT := $(DOCKER_DATA_ROOT_PREFIX)/$(DOCKER_HOSTNAME)
DOCKER_PID := $(DOCKER_RUN_PREFIX)/$(DOCKER_HOSTNAME).pid
EXPERIMENTAL := $(shell test -f /etc/docker/daemon.json && jq -e '.experimental == true' /etc/docker/daemon.json >/dev/null 2>&1 && echo "" || echo "--experimental")
export DOCKER_HOST = $(DOCKER_SOCKET)

# Check existence and status for image and container
DOCKER_DAEMON_RUNNING := $(shell DOCKER_HOST=$(DOCKER_HOST) docker info 2>&1 | grep -q "ERROR" && echo 0 || echo 1)
IMAGE_EXISTS := $(if $(filter 1,$(DOCKER_DAEMON_RUNNING)),$(shell DOCKER_HOST=$(DOCKER_HOST) docker images -a -q -f reference=$(IMAGE_NAME)),)
DANGLING_IMAGE_EXISTS := $(if $(filter 1,$(DOCKER_DAEMON_RUNNING)),$(shell DOCKER_HOST=$(DOCKER_HOST) docker images -a -f dangling=true -q),)
CONTAINER_EXISTS := $(if $(filter 1,$(DOCKER_DAEMON_RUNNING)),$(shell DOCKER_HOST=$(DOCKER_HOST) docker ps -a -q -f name=$(CONTAINER_NAME)),)
VOLUME_EXISTS := $(if $(filter 1,$(DOCKER_DAEMON_RUNNING)),$(shell DOCKER_HOST=$(DOCKER_HOST) docker volume ls -q -f name=$(VOLUME_NAME)),)
# status=(created|restarting|running|removing|paused|exited|dead)
# NOTE: Handle running only
CONTAINER_STATUS := $(if $(CONTAINER_EXISTS),$(shell DOCKER_HOST=$(DOCKER_HOST) docker inspect -f '{{.State.Status}}' $(CONTAINER_NAME)),)
IMAGE_IDS := $(if $(filter 1,$(DOCKER_DAEMON_RUNNING)),$(shell DOCKER_HOST=$(DOCKER_HOST) docker images -a -q),)
CONTAINER_IDS := $(if $(filter 1,$(DOCKER_DAEMON_RUNNING)),$(shell DOCKER_HOST=$(DOCKER_HOST) docker ps -a -q),)

help:
	@echo "targets for handling the Docker image and the container:"; \
	echo "    docker_daemon_start: Start the Docker daemon for the isolated virtual environment; usually call it once for the first time."; \
	echo "    docker_daemon_check: Check if the Docker daemon runs normally after the Docker daemon is running."; \
	echo "    docker_daemon_stop: Stop the Docker daemon and remove all data for it; usually there is no need to call."; \
	echo "    docker_test: Reserve for testing Docker related stuffs."; \
	echo "    docker_prerun: No need to call by user; always check if Docker is installed prior to all targets."; \
	echo "    docker_all: Call docker_prerun, docker_remove, docker_build and docker_run in order."; \
	echo "    docker_check_basic: Check the new Docker daemon runs normally."; \
	echo "    docker_check: Check if the Docker image and the container exist."; \
	echo "    docker_check_detail: Similar to docker_check but with more detailed info."; \
	echo "    docker_build: Build the Docker image only for the first time."; \
	echo "    docker_rebuild: Re-build the Docker image; only call for the environment changed."; \
	echo "    docker_run: Run the Docker container; detached mode is supported if DETACH=1."; \
	echo "    docker_stop: Stop and remove the Docker container."; \
	echo "    docker_remove: Remove both Docker container and image but keep the project directory."; \
	echo "    docker_remove_all: Remove all Docker containers and images but keep the project directory."

include docker.mk
