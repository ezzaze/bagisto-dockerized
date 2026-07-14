#!/bin/sh
# Run on the HOST (not inside a container): rebuilds the Admin, Shop, and
# Installer Vite bundles using a throwaway Node container, so the PHP-FPM
# image never needs Node installed. Usage: ./scripts/rebuild-assets.sh
set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"

build_package() {
    package_path="$1"
    echo "[rebuild-assets] Building ${package_path}..."
    docker run --rm \
        -v "${BACKEND_DIR}:/var/www/html" \
        -w "/var/www/html/${package_path}" \
        node:20-alpine \
        sh -c "npm install --no-audit --no-fund && npm run build"
}

build_package "packages/Webkul/Admin"
build_package "packages/Webkul/Shop"
build_package "packages/Webkul/Installer"

echo "[rebuild-assets] Done."
