
docker_daemon_start:
	@echo "Start new Docker daemon $(DOCKER_HOSTNAME) with experimental feature in the background:"
	@sudo bash -c "dockerd --host $(DOCKER_SOCKET) --pidfile $(DOCKER_PID) --data-root $(DOCKER_DATA_ROOT) $(EXPERIMENTAL) --iptables=true > /dev/null 2>&1 & disown"
	@echo "Sleep 5 seconds to wait for the new Docker daemon starting..."
	@sleep 5
	@echo "Docker daemon started."
	@echo "\nCheck Docker run correctly:"
	@docker run --rm hello-world | grep "Hello"
	@echo "\nCheck new Docker daemon is created:"
	@docker info | grep "Root Dir"
	@echo "\nCheck experimental feature is enabled:"
	@docker info | grep -i "experimental"

docker_daemon_check:
	@echo "Check if Docker daemon $(DOCKER_HOSTNAME) is running:"
	@if docker info 2>&1 | grep -q "ERROR"; then \
		echo "Docker daemon is not running."; \
	else \
		echo "Docker daemon is running."; \
	fi
	@if [ -e $(DOCKER_PID) ]; then \
		echo "Docker PID file $(DOCKER_PID) found."; \
	else \
		echo "Docker PID file $(DOCKER_PID) not found."; \
	fi
	@if [ -e $(DOCKER_SOCKET_FILE) ]; then \
		echo "Docker socket file $(DOCKER_SOCKET_FILE) found."; \
	else \
		echo "Docker socket file $(DOCKER_SOCKET_FILE) not found."; \
	fi
	@if pgrep -a dockerd | grep -q $(DOCKER_SOCKET); then \
		echo "Docker daemon process is running."; \
	else \
		echo "Docker daemon process not found."; \
	fi

docker_daemon_stop:
	@echo "Check if Docker daemon is running before stopping:"
	@DOCKER_STATUS=$$(make --no-print-directory docker_daemon_check | grep -c "Docker daemon process is running."); \
	if [ "$$DOCKER_STATUS" -gt 0 ]; then \
		echo "Stop Docker daemon $(DOCKER_HOSTNAME)..."; \
		sudo kill -9 $$(cat $(DOCKER_PID)); \
		sudo rm -f $(DOCKER_SOCKET_FILE) $(DOCKER_PID); \
		sudo rm -rf $(DOCKER_DATA_ROOT); \
		echo "Docker daemon stopped.\n"; \
	else \
		echo "Docker daemon is not running; nothing to stop.\n"; \
	fi
	@make docker_daemon_check

docker_test:
	@echo "Reserve for testing docker_maker."

docker_prerun:
	@echo "Prerun check: DOCKER_HOST=$(DOCKER_SOCKET)"
	@if ! docker --version; then \
		echo "Docker version does not exist. Please check Docker is installed correctly."; \
		exit 1; \
	fi

docker_check_basic: docker_prerun
	@echo "\nCheck if Docker daemon is running correctly:"
	@docker run --rm hello-world | grep "Hello"
	@echo "\nCheck new Docker daemon root directory:"
	@docker info | grep "Root Dir"
	@echo "\nCheck if experimental feature is enabled:"
	@docker info | grep -i "experimental"

docker_check: docker_check_basic
	@echo "\nCheck if Docker image $(IMAGE_NAME) is built:"
	@if [ -n "$(IMAGE_EXISTS)" ]; then \
		echo "$(IMAGE_EXISTS)"; \
	else \
		echo "Not found."; \
	fi

	@echo "\nCheck if Docker container $(CONTAINER_NAME) is built:"
	@if [ -n "$(CONTAINER_EXISTS)" ]; then \
		echo "$(CONTAINER_EXISTS)"; \
	else \
		echo "Not found."; \
	fi

	@echo "\nCheck the status of Docker container $(CONTAINER_NAME):"
	@if [ -n "$(CONTAINER_EXISTS)" ]; then \
		echo "$(CONTAINER_STATUS)"; \
	else \
		echo "Not found."; \
	fi

docker_check_detail: docker_check_basic
	@echo "\nCheck if Docker image $(IMAGE_NAME) is built(including intermediate images):"
	@docker images -a -f reference=$(IMAGE_NAME)
	@echo "\nCheck if Docker container $(CONTAINER_NAME) is built(including not-running containers):"
	@docker ps -a -f name=$(CONTAINER_NAME)

docker_build: docker_prerun
	@echo "\nCheck if Docker image $(IMAGE_NAME) is built:"
	@if [ -z "$(IMAGE_EXISTS)" ]; then \
		echo "Image $(IMAGE_NAME) is not built. Building..."; \
		docker build -t $(IMAGE_NAME) \
			--build-arg PROJECT_DIR=$(CURRENT_DIR) \
			--build-arg USER=$(USER) \
			--build-arg UID=$(UID) \
			--build-arg GID=$(GID) \
			--build-arg DOCKER_GID=$(DOCKER_GID) \
			$(CURRENT_DIR); \
		echo "Docker image built."; \
	else \
		echo "Image $(IMAGE_NAME) is built."; \
		echo "Please make the target docker_rebuild to rebuild the image."; \
	fi

	@echo "\nCheck if Docker volume $(VOLUME_NAME) is created:"
	@if [ -z "$(VOLUME_EXISTS)" ]; then \
		echo "Volume $(VOLUME_NAME) is not created. Creating..."; \
		docker volume create $(VOLUME_NAME); \
		echo "Docker volume created."; \
	else \
		echo "Volume $(VOLUME_NAME) is created; nothing to create."; \
	fi

docker_rebuild: docker_prerun
	@echo "\nCheck if Docker container $(CONTAINER_NAME) is running:"
	@if [ "$(CONTAINER_STATUS)" = "running" ]; then \
		echo "Container $(CONTAINER_NAME) is running. Stopping..."; \
		docker stop $(CONTAINER_NAME); \
		echo "Docker container stopped."; \
	else \
		echo "Container $(CONTAINER_NAME) is not running; nothing to stop."; \
	fi

	@echo "\nCheck if Docker container $(CONTAINER_NAME) is created:"
	@if [ -n "$(CONTAINER_STATUS)" ]; then \
		echo "Container $(CONTAINER_NAME) is created. Removing..."; \
		docker rm -f $(CONTAINER_NAME); \
		echo "Docker container removed."; \
	else \
		echo "Container $(CONTAINER_NAME) is not created; nothing to remove."; \
	fi

	@echo "\nCheck if Docker image $(IMAGE_NAME) is built:"
	@if [ -n "$(IMAGE_EXISTS)" ]; then \
		echo "Image $(IMAGE_NAME) is built. Removing..."; \
		docker rmi -f $(IMAGE_NAME); \
		echo "Docker image removed."; \
	else \
		echo "Image $(IMAGE_NAME) is not built; nothing to remove."; \
	fi

	@echo "\nCheck if Docker volume $(VOLUME_NAME) is created:"
	@if [ -n "$(VOLUME_EXISTS)" ]; then \
		echo "Volume $(VOLUME_NAME) is created. Removing..."; \
		docker volume rm -f $(VOLUME_NAME); \
		echo "Docker volume removed."; \
	else \
		echo "Volume $(VOLUME_NAME) is not created; nothing to remove."; \
	fi

	@echo "\nRebuild the image $(IMAGE_NAME):"
	@$(MAKE) docker_build

docker_wait: docker_prerun
	@echo "\nCheck if Docker container $(CONTAINER_NAME) is running:"
	@if [ "$(CONTAINER_STATUS)" = "running" ]; then \
		echo "Container $(CONTAINER_NAME) is running. Wait until finishing..."; \
		START_TIME=$$(date +%s); \
		docker wait $(CONTAINER_NAME); \
		END_TIME=$$(date +%s); \
		echo "Execution Time: $$((END_TIME - START_TIME)) seconds"; \
	else \
		echo "Container $(CONTAINER_NAME) is not running; nothing to wait."; \
	fi

docker_stop: docker_prerun
	@echo "\nCheck if Docker container $(CONTAINER_NAME) is running:"
	@if [ "$(CONTAINER_STATUS)" = "running" ]; then \
		echo "Container $(CONTAINER_NAME) is running. Stopping..."; \
		docker stop $(CONTAINER_NAME); \
		echo "Docker container stopped."; \
	else \
		echo "Container $(CONTAINER_NAME) is not running; nothing to stop."; \
	fi

	@echo "\nCheck if Docker container $(CONTAINER_NAME) is created:"
	@if [ -n "$(CONTAINER_STATUS)" ]; then \
		echo "Container $(CONTAINER_NAME) is created. Removing..."; \
		docker rm -f $(CONTAINER_NAME); \
		echo "Docker container removed."; \
	else \
		echo "Container $(CONTAINER_NAME) is not created; nothing to remove."; \
	fi

docker_run: docker_prerun
	@echo "Image name: $(IMAGE_NAME)"
	@echo "Container name: $(CONTAINER_NAME)"
	@echo "Container status: $(CONTAINER_STATUS)"

	@echo "\nCheck the status of Docker container $(CONTAINER_NAME):"
	@if [ "$(CONTAINER_STATUS)" = "running" ]; then \
		echo "Container $(CONTAINER_NAME) is running. Restarting..."; \
		docker restart $(CONTAINER_NAME); \
		echo "Docker container restarted."; \
		docker exec $(RUN_MODE) --privileged $(CONTAINER_NAME) /bin/bash; \
	elif [ -n "$(CONTAINER_STATUS)" ]; then \
		echo "Container $(CONTAINER_NAME) is created but not running. Starting..."; \
		docker start $(CONTAINER_NAME); \
		echo "Docker container started."; \
		docker exec $(RUN_MODE) --privileged $(CONTAINER_NAME) /bin/bash; \
	else \
		echo "Container $(CONTAINER_NAME) is not created. Creating and running..."; \
		$(MAKE) docker_build; \
		docker run $(RUN_MODE) \
			-v $(CURRENT_DIR):$(CURRENT_DIR) \
			-v $(DOCKER_SOCKET_FILE):$(DOCKER_SOCKET_FILE) \
			-e DOCKER_HOST=$(DOCKER_SOCKET) \
			-e VOLUME_NAME=$(VOLUME_NAME) \
			-e VOLUME_PATH=/mnt/$(VOLUME_NAME) \
			--volume $(VOLUME_NAME):/mnt/$(VOLUME_NAME) \
			--hostname=$(HOSTNAME) \
			--group-add docker \
			--privileged \
			--name=$(CONTAINER_NAME) $(IMAGE_NAME) /bin/bash; \
	fi

docker_remove: docker_prerun
	@echo "\nCheck if Docker container $(CONTAINER_NAME) is running:"
	@if [ "$(CONTAINER_STATUS)" = "running" ]; then \
		echo "Container $(CONTAINER_NAME) is running. Stopping..."; \
		docker stop $(CONTAINER_NAME); \
		echo "Docker container stopped."; \
	else \
		echo "Container $(CONTAINER_NAME) is not running; nothing to stop."; \
	fi

	@echo "\nCheck if Docker container $(CONTAINER_NAME) is created:"
	@if [ -n "$(CONTAINER_STATUS)" ]; then \
		echo "Container $(CONTAINER_NAME) is created. Removing..."; \
		docker rm -f $(CONTAINER_NAME); \
		echo "Docker container removed."; \
	else \
		echo "Container $(CONTAINER_NAME) is not created; nothing to remove."; \
	fi

	@echo "\nCheck if Docker image $(IMAGE_NAME) is built:"
	@if [ -n "$(IMAGE_EXISTS)" ]; then \
		echo "Image $(IMAGE_NAME) is built. Removing..."; \
		docker rmi -f $(IMAGE_NAME); \
		echo "Docker image removed."; \
	else \
		echo "Image $(IMAGE_NAME) is not built; nothing to remove."; \
	fi

	@echo "\nCheck if dangling images exist:"
	@if [ -n "$(DANGLING_IMAGE_EXISTS)" ]; then \
		echo "Dangling images exist. Removing..."; \
		docker images -f dangling=true -q | xargs docker rmi; \
		echo "Dangling images removed."; \
	else \
		echo "Dangling images do not exist; nothing to remove."; \
	fi

	@echo "\nCheck if Docker volume $(VOLUME_NAME) is created:"
	@if [ -n "$(VOLUME_EXISTS)" ]; then \
		echo "Volume $(VOLUME_NAME) is created. Removing..."; \
		docker volume rm -f $(VOLUME_NAME); \
		echo "Docker volume removed."; \
	else \
		echo "Volume $(VOLUME_NAME) is not created; nothing to remove."; \
	fi

docker_remove_all: docker_prerun
	@echo "\nCheck if any Docker container is created:"; \
	if [ -n "$(CONTAINER_IDS)" ]; then \
		echo "Some containers are created. Removing..."; \
		docker rm -f $(CONTAINER_IDS); \
		echo "Docker containers all removed."; \
	else \
		echo "No container is created; nothing to remove."; \
	fi

	@echo "\nCheck if any Docker image is built:"; \
	if [ -n "$(IMAGE_IDS)" ]; then \
		echo "Some images are built. Removing..."; \
		docker rmi -f $(IMAGE_IDS); \
		echo "Docker images all removed."; \
	else \
		echo "No image is created; nothing to remove."; \
	fi

docker_all: docker_prerun docker_remove docker_build docker_run

.PHONY: docker_daemon_start docker_daemon_check docker_daemon_stop docker_test docker_prerun docker_all docker_check_basic docker_check docker_check_detail docker_build docker_rebuild docker_wait docker_run docker_stop docker_remove docker_remove_all
