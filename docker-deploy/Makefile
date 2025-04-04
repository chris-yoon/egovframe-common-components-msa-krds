DOCKER_COMPOSE_CMD ?= docker compose
DOCKER_COMPOSE_ENV ?= -f docker-compose.yml --env-file .env

.PHONY: start
start:
	$(DOCKER_COMPOSE_CMD) $(DOCKER_COMPOSE_ENV) up --detach
	@echo ""
	@echo "Egov MSA Com is running."
	@echo "Go to http://localhost:8761 for the discovery server."
	@echo "Go to http://localhost:8888/application/local for the config server."
	@echo "Go to http://localhost:9000/main/ for the main page."

.PHONY: stop
stop:
	$(DOCKER_COMPOSE_CMD) $(DOCKER_COMPOSE_ENV) down
	@echo ""
	@echo "Egov MSA Com is stopped."

