#!/bin/bash
# Respaldo de Pixel Verde: base de datos + archivos de TYPO3.
# Integrante 4 (Orlando). Lo ejecuta cron como root.
# Se instala en /usr/local/sbin/respaldo-pixelverde.sh (ver servidor/respaldo/PASOS.md).
set -euo pipefail

DESTINO=/respaldos
RETENCION_DIAS=7
CONTENEDOR_DB=pixelverde-db
CONTENEDOR_WEB=pixelverde-typo3
FECHA=$(date +%F_%H%M)

umask 077
log() { echo "[$(date '+%F %T')] $*"; }

# 1. El disco de respaldos tiene que estar montado
if ! mountpoint -q "$DESTINO"; then
    log "ERROR: $DESTINO no está montado. No se hace el respaldo."
    exit 1
fi

# Si algo falla a medias, no dejar archivos .parcial tirados
trap 'rm -f "$DESTINO"/*.parcial' EXIT

# 2. Base de datos
log "Respaldando la base de datos..."
docker exec "$CONTENEDOR_DB" sh -c \
    'mariadb-dump -uroot -p"$MARIADB_ROOT_PASSWORD" --single-transaction "$MARIADB_DATABASE"' \
    | gzip > "$DESTINO/typo3_$FECHA.sql.gz.parcial"
gzip -t < "$DESTINO/typo3_$FECHA.sql.gz.parcial"
mv "$DESTINO/typo3_$FECHA.sql.gz.parcial" "$DESTINO/typo3_$FECHA.sql.gz"

# 3. Archivos: imágenes (fileadmin) y configuración (typo3conf)
log "Respaldando fileadmin y typo3conf..."
docker exec "$CONTENEDOR_WEB" tar -czf - -C /var/www/html fileadmin typo3conf \
    > "$DESTINO/archivos_$FECHA.tar.gz.parcial"
gzip -t < "$DESTINO/archivos_$FECHA.tar.gz.parcial"
mv "$DESTINO/archivos_$FECHA.tar.gz.parcial" "$DESTINO/archivos_$FECHA.tar.gz"

# 4. Retención: solo se llega aquí si el respaldo nuevo salió bien
log "Borrando respaldos de más de $RETENCION_DIAS días..."
find "$DESTINO" -maxdepth 1 -type f \
    \( -name 'typo3_*.sql.gz' -o -name 'archivos_*.tar.gz' \) \
    -mtime +"$RETENCION_DIAS" -print -delete

log "Listo: typo3_$FECHA.sql.gz y archivos_$FECHA.tar.gz"
