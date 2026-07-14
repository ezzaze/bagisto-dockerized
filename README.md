# Bagisto

Bagisto 2.4 — the stock Laravel/Vue.js e-commerce platform (Admin panel +
Blade storefront) — fully containerized for local development.

## Architecture

```
project/
├── backend/     Bagisto 2.4 (Laravel 11) — Admin panel + storefront
├── docker/      Dockerfiles (php, nginx) + supervisor configs
├── nginx/       nginx.conf + vhost
├── scripts/     install/update/migrate/seed/clear-cache/optimize/rebuild-assets
├── docker-compose.yml
└── Makefile
```

| Service         | Image                                                  | Purpose                                    |
|-----------------|---------------------------------------------------------|---------------------------------------------|
| `nginx`         | built from `docker/nginx/Dockerfile`                     | reverse proxy, static assets                |
| `app`           | built from `docker/php/Dockerfile` (`dev`)               | PHP-FPM 8.3, serves Admin + storefront       |
| `installer`     | same image                                               | one-shot: installs Bagisto on first boot     |
| `queue`         | same image                                               | `queue:work` under supervisord               |
| `scheduler`     | same image                                               | `schedule:run` loop under supervisord        |
| `mysql`         | `mysql:8.0`                                              | primary datastore                            |
| `redis`         | `redis:7-alpine`                                         | cache, session, queue driver                 |
| `elasticsearch` | `docker.elastic.co/elasticsearch/elasticsearch:8.15.0`   | optional catalog search index                |
| `mailhog`       | `mailhog/mailhog`                                        | catches outgoing email in dev                |

## Prerequisites

- Docker Engine + Docker Compose v2 (`docker compose version` ≥ 2.20)
- ~4 GB RAM free for Elasticsearch + MySQL + PHP-FPM
- Ports `8080, 3307, 6380, 8025, 1025, 9200` free on the host (chosen to avoid
  colliding with the common `80`/`3306`/`6379` defaults — change them in the
  root `.env` if they clash with something else on your machine)

## Quick start

```bash
cp .env.example .env                     # docker-compose-level variables
cp backend/.env.example backend/.env     # Laravel/Bagisto variables
# generate a real APP_KEY into backend/.env before first boot:
docker run --rm -v "$(pwd)/backend:/app" -w /app composer:2 php -r \
  "echo 'base64:'.base64_encode(random_bytes(32));"

docker compose up -d
```

On first boot the `installer` service runs `php artisan bagisto:install
--no-interaction` and writes `backend/storage/installed` as a marker. Every
subsequent `docker compose up -d` sees that marker and skips straight
through — the installer never re-runs and never wipes the database again.

Default admin credentials (unattended install): `admin@example.com` /
`admin123` — **change these immediately** via the Admin panel.

| URL | What |
|---|---|
| http://localhost:8080/ | Storefront |
| http://localhost:8080/admin | Admin panel |
| http://localhost:8025 | Mailhog web UI |
| http://localhost:9200 | Elasticsearch |

Set `BAGISTO_DEMO_SAMPLES=true` in `backend/.env` before the first boot to
seed sample catalog data along with the install.

## Development workflow

- Backend code under `backend/` is bind-mounted into `app`, `queue`, and
  `scheduler` — edit on the host, PHP picks it up immediately (no rebuild).
- Route/config/view caches are **not** baked in dev, so changes are visible
  on the next request. Run `make optimize` only when testing the production
  cache path.
- Rebuilding a container image (e.g. after changing a Dockerfile or PHP
  extension list) still requires `make build`.

### Common commands

```bash
make up              # docker compose up -d
make down            # docker compose down
make build            # rebuild images
make install          # force re-run the installer (drops and reseeds the DB!)
make update           # composer install + migrate + clear caches
make migrate          # php artisan migrate --force
make seed             # php artisan db:seed --force
make clear-cache      # php artisan optimize:clear + cache:clear
make optimize         # bake config/route/view/event caches (prod-style)
make rebuild-assets   # rebuild Admin/Shop/Installer Vite bundles via a throwaway Node container
make logs             # tail all service logs
make shell            # shell into the app container
make ps               # docker compose ps
```

Each of these also has a standalone script under `scripts/` if you'd rather
call `docker compose exec app /var/www/scripts/<name>.sh` directly.

## Troubleshooting

- **`installer` keeps failing / DB errors**: check `docker compose logs
  installer` and `docker compose logs mysql`. The installer waits for MySQL
  to accept connections before running `bagisto:install`, but a slow first
  boot (image build + MySQL data dir init) can still race — re-run `make
  install` once MySQL is healthy (`docker compose ps`).
- **Port already in use**: another project on this machine may already bind
  `80`/`3306`/`6379`. Change the conflicting `*_PORT` variable in the root
  `.env` and re-run `docker compose up -d`.
- **Changed a `.env` value but nothing changed**: config is cached in prod
  mode only; in dev, restart the affected container (`docker compose restart
  app queue scheduler`) so it re-reads `env_file`.
- **Need to start over**: `docker compose down -v` removes the named volumes
  (MySQL/Redis/Elasticsearch data) — the next `up -d` reinstalls from
  scratch. Do **not** run this against anything you care about.

## Production deployment

See `docker/php/Dockerfile`'s `prod` build target (immutable image, `composer
install --no-dev`, OPcache with `validate_timestamps=0`) — a
`docker-compose.prod.yml` overlay and full deployment notes land alongside
the production-hardening phase of this project.
