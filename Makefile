# Langfuse self-host with Podman (Raspberry Pi, Debian, or any Podman host)
#
# Prerequisites:
#   - Podman installed (e.g. apt install podman on Debian)
#   - Podman Compose: either "podman compose" (compose plugin) or "podman-compose"
#
# First-time setup:
#   cp .env.prod.example .env
#   Edit .env and set secrets (NEXTAUTH_SECRET, SALT, ENCRYPTION_KEY, etc.)
#
# Usage:
#   make up      - start all services (default)
#   make down    - stop and remove containers
#   make logs    - follow logs
#   make ps      - list containers

COMPOSE_FILE := docker-compose.yml

# Prefer "podman compose" (built-in); fall back to "podman-compose"
COMPOSE_CMD := $(shell command -v podman-compose >/dev/null 2>&1 && echo podman-compose || echo "podman compose")
# podman-compose (standalone) does not support --wait; only add it for "podman compose"
UP_WAIT := $(shell command -v podman-compose >/dev/null 2>&1 && echo "" || echo "--wait")

.PHONY: up down down-volumes restart logs ps pull check-env help

# Default target: bring up the stack
up: check-env
	$(COMPOSE_CMD) -f $(COMPOSE_FILE) up -d $(UP_WAIT)

# Tear down all services and remove containers
down:
	$(COMPOSE_CMD) -f $(COMPOSE_FILE) down

# Tear down and remove volumes (fresh state; data loss)
down-volumes:
	$(COMPOSE_CMD) -f $(COMPOSE_FILE) down -v

# Restart: down then up
restart: down up

# Follow logs (all services)
logs:
	$(COMPOSE_CMD) -f $(COMPOSE_FILE) logs -f

# List running containers
ps:
	$(COMPOSE_CMD) -f $(COMPOSE_FILE) ps

# Pull latest images (run before 'make up' to avoid slow first start)
pull:
	$(COMPOSE_CMD) -f $(COMPOSE_FILE) pull

# Warn if .env is missing (compose may still use defaults from docker-compose.yml)
check-env:
	@if [ ! -f .env ]; then \
		echo "Warning: .env not found. For production, copy .env.prod.example to .env and set secrets."; \
		echo "  cp .env.prod.example .env"; \
	fi

help:
	@echo "Langfuse self-host (Podman)"
	@echo ""
	@echo "Targets:"
	@echo "  make / make up   - Start all services (detached)"
	@echo "  make down       - Stop and remove containers"
	@echo "  make down-volumes - Stop and remove containers + volumes"
	@echo "  make restart    - down then up"
	@echo "  make logs       - Follow logs"
	@echo "  make ps         - List containers"
	@echo "  make pull       - Pull latest images"
	@echo "  make help       - This message"
	@echo ""
	@echo "Compose command: $(COMPOSE_CMD)"
