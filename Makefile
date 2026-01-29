.PHONY: help init up down restart build logs ps shell artisan composer migrate fresh test cache-clear optimize clean backup

# Default environment
ENV ?= development

# Determine compose file based on environment
ifeq ($(ENV),staging)
    COMPOSE_FILE = docker-compose.staging.yml
else ifeq ($(ENV),production)
    COMPOSE_FILE = docker-compose.prod.yml
else
    COMPOSE_FILE = docker-compose.yml
endif

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

help: ## Show this help message
	@echo '$(YELLOW)Laravel Docker - Makefile Commands$(NC)'
	@echo ''
	@echo '$(GREEN)Usage:$(NC) make [target] ENV=[environment]'
	@echo ''
	@echo '$(GREEN)Environments:$(NC)'
	@echo '  development (default)  - Port 8000'
	@echo '  staging               - Port 8001'
	@echo '  production            - Port 80'
	@echo ''
	@echo '$(GREEN)Setup Commands:$(NC)'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ''
	@echo '$(GREEN)Examples:$(NC)'
	@echo '  make init                    # Setup development'
	@echo '  make up ENV=staging          # Start staging'
	@echo '  make artisan ARGS="migrate"  # Run migration'
	@echo '  make composer ARGS="require laravel/sanctum"'

init: ## Initialize project (creates Laravel app, starts containers, runs migrations)
	@echo '$(GREEN)Initializing Laravel project for $(ENV) environment...$(NC)'
	@if [ ! -f "src/composer.json" ]; then \
		echo '$(YELLOW)Creating Laravel project in src/...$(NC)'; \
		mkdir -p src; \
		docker run --rm -v $(PWD)/src:/app composer create-project laravel/laravel .; \
		echo '$(GREEN)✓ Laravel project created in src/$(NC)'; \
	else \
		echo '$(GREEN)✓ Laravel project already exists in src/$(NC)'; \
	fi
	@if [ ! -f "src/.env" ]; then \
		cp .env.$(ENV) src/.env; \
		echo '$(GREEN)✓ Environment file copied to src/$(NC)'; \
	fi
	@if [ ! -f ".env" ]; then \
		cp .env.$(ENV) .env; \
		echo '$(GREEN)✓ Environment file copied to root (for Docker)$(NC)'; \
	fi
	@echo '$(YELLOW)Building and starting containers...$(NC)'
	@docker compose -f $(COMPOSE_FILE) up -d --build
	@echo '$(YELLOW)Waiting for services to be ready...$(NC)'
	@sleep 10
	@if [ ! -d "src/vendor" ]; then \
		echo '$(YELLOW)Installing dependencies...$(NC)'; \
		docker compose -f $(COMPOSE_FILE) exec -T app composer install --no-interaction --prefer-dist --optimize-autoloader; \
	fi
	@echo '$(YELLOW)Generating application key...$(NC)'
	@docker compose -f $(COMPOSE_FILE) exec -T app php artisan key:generate --force
	@echo '$(YELLOW)Running migrations...$(NC)'
	@docker compose -f $(COMPOSE_FILE) exec -T app php artisan migrate --force || true
	@echo '$(YELLOW)Setting permissions...$(NC)'
	@docker compose -f $(COMPOSE_FILE) exec -T app chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache
	@docker compose -f $(COMPOSE_FILE) exec -T app chmod -R 775 /var/www/storage /var/www/bootstrap/cache
	@echo '$(GREEN)✓ Setup complete!$(NC)'
	@echo '$(GREEN)Access your app at: http://localhost:$(if $(filter staging,$(ENV)),8001,$(if $(filter production,$(ENV)),80,8000))$(NC)'

up: ## Start containers
	@docker compose -f $(COMPOSE_FILE) up -d
	@echo '$(GREEN)✓ Containers started for $(ENV)$(NC)'

down: ## Stop containers
	@docker compose -f $(COMPOSE_FILE) down
	@echo '$(GREEN)✓ Containers stopped for $(ENV)$(NC)'

restart: ## Restart containers
	@docker compose -f $(COMPOSE_FILE) restart
	@echo '$(GREEN)✓ Containers restarted for $(ENV)$(NC)'

build: ## Rebuild containers
	@docker compose -f $(COMPOSE_FILE) build --no-cache
	@echo '$(GREEN)✓ Containers rebuilt for $(ENV)$(NC)'

logs: ## View container logs
	@docker compose -f $(COMPOSE_FILE) logs -f

ps: ## List running containers
	@docker compose -f $(COMPOSE_FILE) ps

shell: ## Access app container shell
	@docker compose -f $(COMPOSE_FILE) exec app bash

artisan: ## Run artisan command (use ARGS="command")
	@docker compose -f $(COMPOSE_FILE) exec app php artisan $(ARGS)

composer: ## Run composer command (use ARGS="command")
	@docker compose -f $(COMPOSE_FILE) exec app composer $(ARGS)

npm: ## Run npm command (use ARGS="command")
	@docker compose -f $(COMPOSE_FILE) exec app npm $(ARGS)

migrate: ## Run database migrations
	@docker compose -f $(COMPOSE_FILE) exec app php artisan migrate --force
	@echo '$(GREEN)✓ Migrations completed$(NC)'

fresh: ## Fresh migration with seeding
	@docker compose -f $(COMPOSE_FILE) exec app php artisan migrate:fresh --seed
	@echo '$(GREEN)✓ Database refreshed and seeded$(NC)'

seed: ## Run database seeders
	@docker compose -f $(COMPOSE_FILE) exec app php artisan db:seed
	@echo '$(GREEN)✓ Database seeded$(NC)'

test: ## Run tests
	@docker compose -f $(COMPOSE_FILE) exec -e APP_ENV=testing app php artisan test

cache-clear: ## Clear all caches
	@docker compose -f $(COMPOSE_FILE) exec app php artisan cache:clear
	@docker compose -f $(COMPOSE_FILE) exec app php artisan config:clear
	@docker compose -f $(COMPOSE_FILE) exec app php artisan view:clear
	@docker compose -f $(COMPOSE_FILE) exec app php artisan route:clear
	@echo '$(GREEN)✓ All caches cleared$(NC)'

optimize: ## Optimize application for production
	@docker compose -f $(COMPOSE_FILE) exec app php artisan config:cache
	@docker compose -f $(COMPOSE_FILE) exec app php artisan route:cache
	@docker compose -f $(COMPOSE_FILE) exec app php artisan view:cache
	@docker compose -f $(COMPOSE_FILE) exec app composer install --optimize-autoloader --no-dev
	@echo '$(GREEN)✓ Application optimized$(NC)'

clean: ## Remove all containers and volumes
	@docker compose -f $(COMPOSE_FILE) down -v
	@echo '$(GREEN)✓ All containers and volumes removed$(NC)'

backup: ## Backup database and storage
	@mkdir -p backups
	@docker compose -f $(COMPOSE_FILE) exec -T mysql mysqldump -u$${DB_USERNAME:-laravel} -p$${DB_PASSWORD:-secret} $${DB_DATABASE:-laravel} > backups/db_$(shell date +%Y%m%d_%H%M%S).sql
	@tar -czf backups/storage_$(shell date +%Y%m%d_%H%M%S).tar.gz storage/ 2>/dev/null || true
	@echo '$(GREEN)✓ Backup completed in backups/$(NC)'

restore: ## Restore database from backup (use FILE=backups/db_xxx.sql)
	@if [ -z "$(FILE)" ]; then \
		echo '$(RED)Error: Please specify FILE=backups/db_xxx.sql$(NC)'; \
		exit 1; \
	fi
	@docker compose -f $(COMPOSE_FILE) exec -T mysql mysql -u$${DB_USERNAME:-laravel} -p$${DB_PASSWORD:-secret} $${DB_DATABASE:-laravel} < $(FILE)
	@echo '$(GREEN)✓ Database restored from $(FILE)$(NC)'

deploy: ## Deploy to environment (stops, rebuilds, migrates, optimizes)
	@echo '$(YELLOW)Deploying to $(ENV)...$(NC)'
	@cp .env.$(ENV) .env
	@cp .env.$(ENV) src/.env
	@echo '$(GREEN)✓ Updated environment files$(NC)'
	@docker compose -f $(COMPOSE_FILE) down
	@docker compose -f $(COMPOSE_FILE) build --no-cache
	@docker compose -f $(COMPOSE_FILE) up -d
	@sleep 5
	@docker compose -f $(COMPOSE_FILE) exec -T app php artisan migrate --force
	@if [ "$(ENV)" = "production" ]; then \
		docker compose -f $(COMPOSE_FILE) exec -T app php artisan optimize; \
	fi
	@echo '$(GREEN)✓ Deployment complete!$(NC)'

mysql: ## Access MySQL shell
	@docker compose -f $(COMPOSE_FILE) exec mysql mysql -u$${DB_USERNAME:-laravel} -p$${DB_PASSWORD:-secret} $${DB_DATABASE:-laravel}

redis: ## Access Redis CLI
	@docker compose -f $(COMPOSE_FILE) exec redis redis-cli

permissions: ## Fix storage and cache permissions
	@docker compose -f $(COMPOSE_FILE) exec app chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache
	@docker compose -f $(COMPOSE_FILE) exec app chmod -R 775 /var/www/storage /var/www/bootstrap/cache
	@echo '$(GREEN)✓ Permissions fixed$(NC)'
