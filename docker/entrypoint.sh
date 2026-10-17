#!/bin/bash
# =============================================================================
#  Arranque del contenedor TYPO3 (Pixel Verde)
#
#  1. Si TYPO3 no está instalado (no existe typo3conf/system/settings.php),
#     lo instala solo con "typo3 setup", usando las variables del .env.
#  2. Copia config/additional.php (dominio permitido + proxy inverso).
#  3. Arranca Apache en primer plano (si Apache termina, el contenedor termina).
#
#  Como los datos viven en volúmenes con nombre, la instalación ocurre UNA vez.
#  En los siguientes arranques solo se ve "TYPO3 ya está instalado".
# =============================================================================
set -e

cd /var/www/html
SETTINGS=typo3conf/system/settings.php
TYPO3_CLI=./typo3/sysext/core/bin/typo3

# Los volúmenes recién creados heredan el dueño de la imagen, pero por si acaso:
mkdir -p fileadmin typo3conf/system typo3temp
chown www-data:www-data fileadmin typo3conf typo3conf/system typo3temp

if [ ! -f "$SETTINGS" ]; then
    echo "[pixelverde] TYPO3 no está instalado todavía: ejecutando 'typo3 setup'..."

    # depends_on + healthcheck ya esperan a MariaDB, pero damos margen extra
    for i in $(seq 1 30); do
        if php -r '$c=@mysqli_connect(getenv("TYPO3_DB_HOST"),getenv("TYPO3_DB_USERNAME"),getenv("TYPO3_DB_PASSWORD"),getenv("TYPO3_DB_DBNAME"),(int)getenv("TYPO3_DB_PORT")); exit($c?0:1);'; then
            break
        fi
        echo "[pixelverde] Esperando a la base de datos ($i/30)..."
        sleep 2
    done

    # Si no se eligió distribución, no se le pasa la variable vacía al comando
    if [ -z "${TYPO3_SETUP_DISTRIBUTION}" ]; then
        unset TYPO3_SETUP_DISTRIBUTION
    fi

    if gosu www-data "$TYPO3_CLI" setup --no-interaction --force --server-type=apache; then
        echo "[pixelverde] Instalación de TYPO3 terminada."
    else
        echo "[pixelverde] ERROR: 'typo3 setup' falló. Revisá las variables del .env"
        echo "[pixelverde] (la clave del admin debe tener mayúscula, minúscula, número y símbolo)."
        echo "[pixelverde] Apache arranca igual para que puedas revisar con: docker compose logs typo3"
    fi
else
    echo "[pixelverde] TYPO3 ya está instalado ($SETTINGS existe). No se reinstala."
fi

# Configuración gestionada por la imagen (se reescribe en cada arranque)
if [ -d typo3conf/system ]; then
    cp /usr/local/share/typo3/additional.php typo3conf/system/additional.php
    chown www-data:www-data typo3conf/system/additional.php
fi

# Pasa el control al comando del contenedor (por defecto: apache2-foreground)
exec docker-php-entrypoint "$@"
