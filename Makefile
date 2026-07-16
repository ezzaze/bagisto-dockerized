.PHONY: up down build install update migrate seed clear-cache optimize rebuild-assets logs shell shell-mysql restart ps \
	prod-build prod-up prod-down prod-install prod-logs prod-ps

# Production compose file (self-contained; see docker-compose.prod.yml header).
PROD := docker compose -f docker-compose.prod.yml

up:
	docker compose up -d

down:
	docker compose down

build:
	docker compose build

# Force-run the installer even if backend/storage/installed already exists.
install:
	docker compose run --rm installer /var/www/scripts/install.sh

update:
	docker compose exec app /var/www/scripts/update.sh

migrate:
	docker compose exec app /var/www/scripts/migrate.sh

seed:
	docker compose exec app /var/www/scripts/seed.sh

clear-cache:
	docker compose exec app /var/www/scripts/clear-cache.sh

optimize:
	docker compose exec app /var/www/scripts/optimize.sh

rebuild-assets:
	./scripts/rebuild-assets.sh

logs:
	docker compose logs -f

restart:
	docker compose restart

ps:
	docker compose ps

# --- Production -----------------------------------------------------------
# Uses the immutable prod image (code + vendor baked in), no bind mounts.
prod-build:
	$(PROD) build

prod-up:
	$(PROD) up -d

prod-down:
	$(PROD) down

# Force-run the prod installer/optimize pass (normally runs on prod-up).
prod-install:
	$(PROD) run --rm installer sh -c '/var/www/scripts/install.sh && php artisan storage:link --force && /var/www/scripts/optimize.sh'

prod-logs:
	$(PROD) logs -f

prod-ps:
	$(PROD) ps

shell:
	docker compose exec app sh

shell-mysql:
	docker compose exec mysql mysql -u$${DB_USERNAME:-bagisto} -p$${DB_PASSWORD:-bagisto_dev_secret} $${DB_DATABASE:-bagisto}
