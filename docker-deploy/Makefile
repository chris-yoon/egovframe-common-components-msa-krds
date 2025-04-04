DOCKER_COMPOSE_CMD ?= docker compose
DOCKER_COMPOSE_ENV ?= --env-file .env
DOCKER_COMPOSE_FILE ?= -f docker-compose.yml
DOCKER_COMPOSE_FILE_SCALE ?= -f docker-compose.board-scale.yml

.PHONY: start
start:
	$(DOCKER_COMPOSE_CMD) $(DOCKER_COMPOSE_ENV) $(DOCKER_COMPOSE_FILE) up --detach
	@echo ""
	@echo "Egov MSA Com is running."
	@echo "Go to http://localhost:8761 for the discovery server."
	@echo "Go to http://localhost:8888/application/local for the config server."
	@echo "Go to http://localhost:9000/main/ for the main page."

.PHONY: stop
stop:
	$(DOCKER_COMPOSE_CMD) $(DOCKER_COMPOSE_ENV) $(DOCKER_COMPOSE_FILE) $(DOCKER_COMPOSE_FILE_SCALE) down
	@echo ""
	@echo "Egov MSA Com is stopped."

.PHONY: scale-out
scale-out:
	$(DOCKER_COMPOSE_CMD) $(DOCKER_COMPOSE_ENV) $(DOCKER_COMPOSE_FILE_SCALE) up --detach

.PHONY: scale-down
scale-down:
	$(DOCKER_COMPOSE_CMD) $(DOCKER_COMPOSE_ENV) $(DOCKER_COMPOSE_FILE_SCALE) down
