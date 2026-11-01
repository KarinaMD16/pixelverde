#!/bin/bash
# =============================================================================
#  Restauración de Pixel Verde: base de datos y, si se indica, archivos de TYPO3.
#  Integrante 4 (respaldos). Es la contraparte de respaldo-pixelverde.sh.
#  Se instala en /usr/local/sbin/restaurar-pixelverde.sh (ver servidor/respaldo/PASOS.md).
#
#  Uso (como root):
#     restaurar-pixelverde.sh /respaldos/typo3_AAAA-MM-DD_HHMM.sql.gz
#     restaurar-pixelverde.sh /respaldos/typo3_AAAA-MM-DD_HHMM.sql.gz /respaldos/archivos_AAAA-MM-DD_HHMM.tar.gz
#
#  Qué hace:
#   1. Revisa que los respaldos existan y no estén dañados (gzip -t).
#   2. Pide confirmación: la base actual se reemplaza.
#   3. Guarda una copia de la base actual (por si la restauración fue un error).
#   4. Vacía la base y carga el respaldo.
#   5. Si se pasó el segundo archivo, restaura fileadmin y typo3conf.
#   6. Limpia las cachés de TYPO3 y comprueba que el sitio responda.
#
#  Como el script de respaldo, no tiene claves: las lee dentro del contenedor.
# =============================================================================
set -euo pipefail

DESTINO=/respaldos
CONTENEDOR_DB=pixelverde-db
CONTENEDOR_WEB=pixelverde-typo3
FECHA=$(date +%F_%H%M)

umask 077
log() { echo "[$(date '+%F %T')] $*"; }
error() { log "ERROR: $*"; exit 1; }

# --- 0. Revisiones previas ----------------------------------------------------
[ "$(id -u)" -eq 0 ] || error "hay que correrlo como root: sudo $0 ..."

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Uso: $0 /respaldos/typo3_FECHA.sql.gz [/respaldos/archivos_FECHA.tar.gz]"
    echo
    echo "Respaldos disponibles:"
    ls -lt "$DESTINO" 2>/dev/null | grep -E 'typo3_|archivos_' | head -14 || true
    exit 1
fi

RESPALDO_DB=$1
RESPALDO_ARCHIVOS=${2:-}

[ -f "$RESPALDO_DB" ] || error "no existe $RESPALDO_DB"
gzip -t "$RESPALDO_DB" || error "$RESPALDO_DB está dañado (gzip -t falló)"

if [ -n "$RESPALDO_ARCHIVOS" ]; then
    [ -f "$RESPALDO_ARCHIVOS" ] || error "no existe $RESPALDO_ARCHIVOS"
    gzip -t "$RESPALDO_ARCHIVOS" || error "$RESPALDO_ARCHIVOS está dañado (gzip -t falló)"
fi

for c in "$CONTENEDOR_DB" "$CONTENEDOR_WEB"; do
    [ "$(docker inspect -f '{{.State.Running}}' "$c" 2>/dev/null)" = "true" ] \
        || error "el contenedor $c no está corriendo (docker compose up -d)"
done

# --- 1. Confirmación ----------------------------------------------------------
echo "Se va a REEMPLAZAR la base de datos actual con:"
echo "   $RESPALDO_DB"
[ -n "$RESPALDO_ARCHIVOS" ] && echo "y los archivos (fileadmin y typo3conf) con:" && echo "   $RESPALDO_ARCHIVOS"
read -r -p "Escriba RESTAURAR para continuar: " RESPUESTA
[ "$RESPUESTA" = "RESTAURAR" ] || error "cancelado, no se cambió nada"

# --- 2. Copia de seguridad de lo que hay ahora ---------------------------------
# No usa el nombre typo3_*.sql.gz para no confundirse con los respaldos diarios.
# Si la base ya está borrada o dañada, esta copia puede fallar: no se detiene.
COPIA="$DESTINO/prerestauracion_$FECHA.sql.gz"
log "Guardando la base actual en $COPIA ..."
if docker exec "$CONTENEDOR_DB" sh -c \
     'mariadb-dump -uroot -p"$MARIADB_ROOT_PASSWORD" --single-transaction "$MARIADB_DATABASE"' \
     2>/dev/null | gzip > "$COPIA"; then
    log "Copia guardada."
else
    rm -f "$COPIA"
    log "Aviso: no se pudo copiar la base actual (puede que ya no exista). Se sigue."
fi

# --- 3. Base de datos ---------------------------------------------------------
# El respaldo trae las tablas, pero no la instrucción para crear la base.
log "Vaciando la base de datos..."
docker exec "$CONTENEDOR_DB" sh -c \
    'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS $MARIADB_DATABASE; CREATE DATABASE $MARIADB_DATABASE CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"'

# La -i de docker exec es obligatoria: sin ella termina "bien" pero no carga nada.
# Se usa el cliente mariadb del mismo contenedor que hizo el respaldo.
log "Cargando $RESPALDO_DB ..."
gunzip -c "$RESPALDO_DB" | docker exec -i "$CONTENEDOR_DB" sh -c \
    'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" "$MARIADB_DATABASE"'

# --- 4. Archivos (opcional) ---------------------------------------------------
# fileadmin = imágenes del portafolio; typo3conf = settings.php y el sitio.
# Con el bono activo, typo3-2 usa los mismos volúmenes: se restaura una sola vez.
if [ -n "$RESPALDO_ARCHIVOS" ]; then
    log "Restaurando fileadmin y typo3conf desde $RESPALDO_ARCHIVOS ..."
    docker exec -i "$CONTENEDOR_WEB" tar -xzf - -C /var/www/html < "$RESPALDO_ARCHIVOS"
    docker exec "$CONTENEDOR_WEB" chown -R www-data:www-data /var/www/html/fileadmin /var/www/html/typo3conf
fi

# --- 5. Cachés y comprobación ------------------------------------------------
log "Limpiando cachés de TYPO3..."
docker exec -u www-data "$CONTENEDOR_WEB" ./typo3/sysext/core/bin/typo3 cache:flush

PAGINAS=$(docker exec "$CONTENEDOR_DB" sh -c \
    'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" "$MARIADB_DATABASE" -N -e "SELECT COUNT(*) FROM pages WHERE deleted=0;"')
CODIGO=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/typo3/ || true)

log "Páginas en la base: $PAGINAS"
log "Backend de TYPO3 (http://127.0.0.1:8080/typo3/): HTTP $CODIGO"

if [ "$CODIGO" = "200" ] && [ "$PAGINAS" -gt 0 ]; then
    log "Listo: restauración terminada."
else
    error "la restauración terminó, pero el sitio no responde bien. Revisar: docker compose logs typo3"
fi
