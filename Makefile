NAME        = inception
COMPOSE_FILE = ./srcs/docker-compose.yml
DATA_DIR    = /home/spujol-s/data

all: up

build:
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress
	docker compose -f $(COMPOSE_FILE) build

up:
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress
	docker compose -f $(COMPOSE_FILE) up -d --build

down:
	docker compose -f $(COMPOSE_FILE) down

stop:
	docker compose -f $(COMPOSE_FILE) stop

start:
	docker compose -f $(COMPOSE_FILE) start

logs:
	docker compose -f $(COMPOSE_FILE) logs -f

ps:
	docker compose -f $(COMPOSE_FILE) ps

clean: down
	docker system prune -a --force

fclean:
	@docker compose -f $(COMPOSE_FILE) down -v --rmi all --remove-orphans 2>/dev/null || true
	@docker system prune -a --volumes --force
	@sudo rm -rf $(DATA_DIR)/mariadb/* $(DATA_DIR)/wordpress/*
	@echo "Cleaned all Docker data and host volumes."

re: fclean all

.PHONY: all build up down stop start logs ps clean fclean re
