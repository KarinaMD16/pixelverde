# servidor/respaldo — Integrante 4 (respaldos)

Aquí van el script de respaldo, la línea del `crontab` y el `PASOS.md` de la prueba de restauración.

**Los datos que necesitás del Integrante 1 están fijos en `docker-compose.yml`:**

| Dato | Valor |
|---|---|
| Contenedor de la base | `pixelverde-db` |
| Contenedor de TYPO3 | `pixelverde-typo3` |
| Nombre de la base | el de `DB_NAME` en el `.env` (por defecto `typo3`) |
| Clave de root dentro del contenedor | variable `MARIADB_ROOT_PASSWORD` |
| Volumen de la base | `pixelverde_datos_db` |
| Volumen de imágenes/archivos | `pixelverde_datos_fileadmin` |

Ejemplo de volcado (la clave se lee dentro del contenedor, no se escribe en el script):

```bash
docker exec pixelverde-db sh -c 'mariadb-dump -uroot -p"$MARIADB_ROOT_PASSWORD" --single-transaction typo3' | gzip > /respaldos/typo3_$(date +%F_%H%M).sql.gz
```

Las imágenes del portafolio **no** están en la base: están en el volumen `pixelverde_datos_fileadmin`.
Un respaldo completo incluye los dos.
