# PASOS — Respaldo automático y restauración

**Encargado:** Orlando · **Rol:** FTP y respaldos (Integrante 4)
**Requisito que cubre:** Común #5 — respaldo automático de la base de datos con Cron, con una prueba de restauración documentada.

Todos los comandos se corren en el **servidor**, dentro de la carpeta del repo (`cd ~/pixelverde`), salvo que diga otra cosa. TYPO3 tiene que estar corriendo (`docker compose ps`).

---

## 1. Resumen

| Qué | Cómo quedó |
|---|---|
| Qué se respalda | Base de datos (`typo3_FECHA.sql.gz`) + `fileadmin` y `typo3conf` (`archivos_FECHA.tar.gz`) |
| Dónde | `/respaldos`, en un **segundo disco virtual** (`ext4`, montado por UUID, `nofail`), solo root (`700`) |
| Script | `/usr/local/sbin/respaldo-pixelverde.sh` (root, `700`) |
| Cuándo | Todos los días a las **2:00 a. m.** (crontab de root), zona `America/Costa_Rica` |
| Retención | **7 días**; lo más viejo se borra solo, y solo si el respaldo nuevo salió bien |
| Log | `/var/log/respaldo-pixelverde.log` |

### Archivos del repo y a dónde van

| Archivo del repo | Se copia a |
|---|---|
| `servidor/respaldo/respaldo-pixelverde.sh` | `/usr/local/sbin/respaldo-pixelverde.sh` |
| `servidor/respaldo/crontab.txt` | crontab de root (`sudo crontab`) |

El script **no tiene claves**: lee `MARIADB_ROOT_PASSWORD` y `MARIADB_DATABASE` dentro del contenedor `pixelverde-db`, que las toma del `.env`.

### Datos que vienen del Integrante 1 (`docker-compose.yml`)

| Dato | Valor |
|---|---|
| Contenedor de la base | `pixelverde-db` |
| Contenedor de TYPO3 | `pixelverde-typo3` |
| Nombre de la base | `DB_NAME` del `.env` (por defecto `typo3`) → dentro del contenedor es `$MARIADB_DATABASE` |
| Clave de root dentro del contenedor | `$MARIADB_ROOT_PASSWORD` |
| Volúmenes | `pixelverde_datos_db`, `pixelverde_datos_fileadmin`, `pixelverde_datos_typo3conf` |

---

## 2. Decisiones y por qué

### 2.1 Qué se respalda

| Qué | Por qué |
|---|---|
| **Base de datos** | Páginas, proyectos, usuarios y permisos. Es lo que pide el enunciado |
| **`fileadmin`** | Las imágenes del portafolio **no** están en la base. Sin esto se restauran proyectos sin imágenes |
| **`typo3conf`** | `settings.php` (llave de cifrado, conexión a la base) y la configuración del sitio. Si se pierde ese volumen, el contenedor reinstala TYPO3 desde cero al arrancar |

### 2.2 Segundo disco en `/respaldos`

- Si el respaldo vive en el mismo disco que la base y ese disco falla, se pierden las dos cosas a la vez.
- Queda fuera de la carpeta del proyecto y de los volúmenes de Docker: un `docker compose down -v` o un `rm` equivocado en `~/pixelverde` no lo toca.
- Simula un almacenamiento externo.
- **Montado por UUID**: el nombre `sdb` puede cambiar si se agrega otro disco; el UUID no.
- **`nofail`**: si el disco falta, el servidor arranca igual (sin eso, Ubuntu queda en modo de emergencia).
- **`700` root**: cada respaldo tiene la base completa, incluidos los hash de las claves del backend.

### 2.3 Frecuencia: diario a las 2:00 a. m.

- El contenido del portafolio cambia pocas veces por semana, no cada minuto. Con un respaldo diario, **lo máximo que se pierde es un día de cambios**.
- A las 2:00 a. m. nadie está editando.
- Cada hora serían 168 respaldos por semana de algo que casi no cambia. Cada semana se arriesgarían 7 días de trabajo.

### 2.4 Retención: 7 días

- Si alguien borra un proyecto el viernes y lo nota el lunes, todavía existe un respaldo de antes del error.
- Espacio: hoy cada par pesa ~13 KB. Aunque con imágenes llegue a 50 MB, 7 × 50 MB = 350 MB en un disco de 5 GB.
- Los respaldos viejos se borran **al final** del script: si el respaldo nuevo falla, el script se detiene antes y los viejos se conservan.

### 2.5 Cómo está hecho el script

| Decisión | Por qué |
|---|---|
| `set -euo pipefail` | Se detiene en el primer error. Sin `pipefail`, si `mariadb-dump` falla, `gzip` igual termina bien y queda un `.sql.gz` vacío **que parece válido** |
| `mountpoint -q /respaldos` | Si el disco no montó (por `nofail`), `/respaldos` sería una carpeta vacía en el disco del sistema. Sin esta revisión los respaldos caerían ahí en silencio |
| Clave leída dentro del contenedor | El script va a Git sin exponer nada |
| `$MARIADB_DATABASE` en vez de `typo3` | Si cambia `DB_NAME` en el `.env`, el script sigue funcionando |
| `--single-transaction` | Copia consistente de la base sin bloquear el sitio |
| Escribe `.parcial` y luego `mv` | Un archivo a medias nunca queda con nombre de respaldo válido |
| `gzip -t` | Verifica que el comprimido no esté dañado antes de darlo por bueno |
| `umask 077` | Los respaldos quedan `-rw-------` (solo root) |
| Vive en `/usr/local/sbin/`, no en `~/pixelverde` | Cron lo corre como root: un archivo que corre como root no debe estar donde otro usuario o un `git pull` lo pueden cambiar sin revisión |
| Crontab de **root** | Necesita Docker y escribir en `/respaldos` |
| Salida a `/var/log/respaldo-pixelverde.log` | Cron corre sin pantalla; sin el log, los errores se pierden |

---

## 3. Requisito previo: zona horaria

El servidor viene en UTC. Con UTC, `0 2 * * *` sería **2:00 UTC = 8:00 p. m. en Costa Rica**.

```bash
sudo timedatectl set-timezone America/Costa_Rica
timedatectl                                 # Time zone: America/Costa_Rica (CST, -0600)
                                            # System clock synchronized: yes
```

Es un ajuste de todo el servidor: se coordina con Karina (dueña del servidor oficial).

---

## 4. Segundo disco para `/respaldos`

### 4.1 Crear el disco en VirtualBox [PC]

1. Apagar la VM (`sudo poweroff`).
2. VM → **Configuración → Almacenamiento → Controlador: SATA → Agregar disco duro → Crear**.
3. **VDI**, **Reservado dinámicamente**, **5 GB**, nombre `respaldos`.
4. Aceptar y encender la VM.

### 4.2 Identificar el disco

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
```

Buscar el disco de **5G sin particiones ni punto de montaje**. En la VM de práctica fue `sdb`. **Confirmar el nombre antes de seguir**: el paso siguiente borra ese disco.

### 4.3 Particionar, formatear y montar

> Cambiar `sdb` si en el paso 4.2 salió otro nombre. Estos comandos borran el disco indicado.

```bash
sudo parted /dev/sdb --script mklabel gpt mkpart respaldos ext4 0% 100%
lsblk /dev/sdb                              # aparece sdb1
sudo mkfs.ext4 -L respaldos /dev/sdb1

sudo mkdir -p /respaldos
UUID=$(sudo blkid -s UUID -o value /dev/sdb1)
grep -q ' /respaldos ' /etc/fstab || echo "UUID=$UUID /respaldos ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
sudo systemctl daemon-reload
sudo mount -a

sudo chmod 700 /respaldos
```

| Parte de la línea de `fstab` | Significa |
|---|---|
| `UUID=...` | Identifica el disco aunque cambie su nombre (`sdb`, `sdc`…) |
| `defaults,nofail` | Si el disco falta, el servidor arranca igual |
| `0 2` | Sin `dump`; revisar el disco al arrancar, después de `/` |

El `chmod 700` va **después** de montar: cuentan los permisos de la raíz del disco montado.

### 4.4 Comprobar (también después de reiniciar)

```bash
findmnt /respaldos                          # /respaldos /dev/sdb1 ext4
df -h /respaldos                            # ~4.9G
ls -ld /respaldos                           # drwx------ root root
sudo reboot
# al volver:
findmnt /respaldos && ls -ld /respaldos
```

Adentro aparece `lost+found`: es normal en ext4.

---

## 5. Instalar el script

```bash
sudo install -o root -g root -m 700 servidor/respaldo/respaldo-pixelverde.sh /usr/local/sbin/respaldo-pixelverde.sh
ls -l /usr/local/sbin/respaldo-pixelverde.sh    # -rwx------ root root
```

`install` copia y fija dueño y permisos en un solo paso (Git en Windows no guarda el permiso de ejecución).

Probarlo a mano:

```bash
sudo /usr/local/sbin/respaldo-pixelverde.sh
sudo ls -lh /respaldos
```

Salida esperada:

```
[2026-10-18 17:18:44] Respaldando la base de datos...
[2026-10-18 17:18:46] Respaldando fileadmin y typo3conf...
[2026-10-18 17:18:47] Borrando respaldos de más de 7 días...
[2026-10-18 17:18:47] Listo: typo3_2026-10-18_1718.sql.gz y archivos_2026-10-18_1718.tar.gz
```

Revisar que no estén vacíos (el `*` tiene que resolverlo root, ver error 1):

```bash
sudo sh -c 'zcat /respaldos/typo3_*.sql.gz | head -n 5'                   # -- MariaDB dump ... Database: typo3
sudo sh -c 'zcat /respaldos/typo3_*.sql.gz | grep -c "CREATE TABLE"'      # ~42 tablas
sudo sh -c 'tar -tzf /respaldos/archivos_*.tar.gz | grep settings.php'    # typo3conf/system/settings.php
```

---

## 6. Programarlo con cron

### 6.1 Prueba con frecuencia corta

Cron corre con un entorno mínimo (otro `PATH`, sin variables del usuario): lo que funciona a mano puede fallar ahí. Primero se prueba cada 2 minutos:

```bash
( sudo crontab -l 2>/dev/null | grep -v respaldo-pixelverde
  echo '*/2 * * * * /usr/local/sbin/respaldo-pixelverde.sh >> /var/log/respaldo-pixelverde.log 2>&1'
) | sudo crontab -
```

Esperar ~5 minutos:

```bash
sudo cat /var/log/respaldo-pixelverde.log                     # varios bloques "Listo: ..."
sudo ls -l /respaldos                                         # varios pares con horas distintas
journalctl -u cron --since "10 min ago" --no-pager | grep respaldo   # (root) CMD (...)
```

### 6.2 Dejarlo a las 2:00 a. m.

```bash
( sudo crontab -l 2>/dev/null | grep -v respaldo-pixelverde
  grep -v '^#' servidor/respaldo/crontab.txt
) | sudo crontab -
sudo crontab -l
# 0 2 * * * /usr/local/sbin/respaldo-pixelverde.sh >> /var/log/respaldo-pixelverde.log 2>&1
```

El comando toma el crontab actual, le quita la línea vieja del respaldo y agrega la del repo: no se duplica aunque se corra varias veces.

| Campo | `0 2 * * *` |
|---|---|
| minuto | `0` |
| hora | `2` |
| día del mes / mes / día de la semana | todos |

### 6.3 Probar la retención sin esperar 7 días

```bash
sudo touch -d '10 days ago' /respaldos/typo3_2026-10-08_0200.sql.gz
sudo /usr/local/sbin/respaldo-pixelverde.sh     # el find imprime /respaldos/typo3_2026-10-08_0200.sql.gz
sudo ls -l /respaldos | grep 10-08              # ya no aparece
```

`touch -d` le pone fecha de hace 10 días; `find -mtime +7` usa esa fecha.

---

## 7. Restauración

### 7.1 Restaurar la base de datos

Elegir el respaldo (el más reciente que **sí** tenga lo que se quiere recuperar):

```bash
sudo ls -lt /respaldos | head
RESPALDO=/respaldos/typo3_AAAA-MM-DD_HHMM.sql.gz
```

Si la base todavía existe pero está dañada, o si ya no existe, se deja vacía y lista:

```bash
docker exec pixelverde-db sh -c 'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS $MARIADB_DATABASE; CREATE DATABASE $MARIADB_DATABASE;"'
```

Restaurar y limpiar cachés:

```bash
sudo gunzip -c "$RESPALDO" | docker exec -i pixelverde-db sh -c 'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" "$MARIADB_DATABASE"'
docker exec -u www-data pixelverde-typo3 ./typo3/sysext/core/bin/typo3 cache:flush
```

| Detalle | Por qué |
|---|---|
| `CREATE DATABASE` antes | El respaldo trae las tablas pero no la instrucción para crear la base |
| Los permisos del usuario `typo3` | Sobreviven al `DROP DATABASE`: TYPO3 vuelve a conectarse sin tocar nada |
| `sudo gunzip -c` con ruta exacta | `/respaldos` es solo de root; sin `*`, `sudo` abre el archivo directamente |
| `docker exec -i` | La `-i` pasa la tubería al `mariadb` del contenedor. **Sin `-i` termina "bien" pero no restaura nada** |
| Cliente `mariadb` del mismo contenedor | Es la versión que hizo el respaldo y entiende su primera línea (`/*M!999999\- enable the sandbox mode */`) |
| `cache:flush` como `www-data` | Las cachés en archivos (`typo3temp`) no se borraron; se regeneran con el dueño correcto |

### 7.2 Restaurar imágenes y configuración

> **Pendiente de probar** en la Sesión 2, con las imágenes reales del portafolio.

```bash
ARCHIVOS=/respaldos/archivos_AAAA-MM-DD_HHMM.tar.gz
sudo cat "$ARCHIVOS" | docker exec -i pixelverde-typo3 tar -xzf - -C /var/www/html
docker exec -u www-data pixelverde-typo3 ./typo3/sysext/core/bin/typo3 cache:flush
```

---

## 8. Prueba de restauración (la que se califica)

Se practicó en una VM propia el 18/10/2026 con una página de prueba. **Se repite en el servidor oficial cuando Diana haya cargado el portafolio real**, para mostrar que vuelve todo.

| # | Momento | Comando | Resultado en la práctica |
|---|---|---|---|
| 1 | Antes | `SELECT uid, title FROM pages;` (ver abajo) + sitio en el navegador | `1 Home`, `2 Prueba de restauracion` |
| 2 | Respaldo | `sudo /usr/local/sbin/respaldo-pixelverde.sh` | `Listo: typo3_2026-10-18_1738.sql.gz ...` |
| 3 | Desastre | `DROP DATABASE` (ver abajo) | — |
| 4 | Sitio roto | `SELECT` + `curl -sI http://127.0.0.1:8080/typo3/ \| head -n 1` | `ERROR 1146 ... Table 'typo3.pages' doesn't exist` · `HTTP/1.1 500 Internal Server Error` |
| 5 | Restaurar | sección 7.1 | sin errores |
| 6 | Después | `SELECT` + `curl` + navegador | vuelven `Home` y `Prueba de restauracion` · `HTTP/1.1 200 OK` |

Comandos de los momentos 1, 3 y 4:

```bash
# Consultar las páginas
docker exec pixelverde-db sh -c 'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" "$MARIADB_DATABASE" -e "SELECT uid, title, hidden, deleted FROM pages;"'

# Desastre: borrar la base (solo con un respaldo reciente y el grupo avisado)
docker exec pixelverde-db sh -c 'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" -e "DROP DATABASE $MARIADB_DATABASE; CREATE DATABASE $MARIADB_DATABASE;"'

# Estado del sitio
curl -sI http://127.0.0.1:8080/typo3/ | head -n 1
```

Para ver el backend desde Windows en la VM de práctica (TYPO3 solo escucha en `127.0.0.1:8080`), un túnel SSH desde Windows:

```bash
ssh -p 2222 -L 8080:127.0.0.1:8080 usuario@127.0.0.1
```

y en el navegador `http://localhost:8080/typo3/`. En el servidor oficial se usa `https://pixelverde.internal/typo3/` desde Mint.

---


## 9. Errores encontrados

### Error 1 — `gzip: /respaldos/typo3_*.sql.gz: No such file or directory`

**Síntoma:** `sudo zcat /respaldos/typo3_*.sql.gz` no encontraba los archivos, aunque `sudo ls` sí los mostraba.
**Causa:** el `*` lo resuelve el shell del usuario **antes** de `sudo`, y ese usuario no puede leer `/respaldos` (`700`). El shell deja el `*` literal. Es la prueba de que los permisos funcionan.
**Solución:** que el `*` lo resuelva root: `sudo sh -c 'zcat /respaldos/typo3_*.sql.gz | head'`, o usar la ruta exacta.

### Error 2 — Zona horaria en UTC

**Síntoma:** `timedatectl` mostraba `Etc/UTC`.
**Causa:** Ubuntu Server se instala en UTC. `0 2 * * *` habría corrido a las 8:00 p. m. de Costa Rica.
**Solución:** `sudo timedatectl set-timezone America/Costa_Rica` (sección 3).

### Nota — Primera línea del respaldo: `/*M!999999\- enable the sandbox mode */`

MariaDB 10.11.19 la agrega a sus respaldos. Un cliente MySQL o un MariaDB más viejo falla con `Unknown command '\-'`. Por eso se restaura con el cliente `mariadb` del mismo contenedor.

---

## 10. Limitación conocida (trade-off)

El servidor oficial es una VM en una laptop: **a las 2:00 a. m. probablemente esté apagada**, y cron no recupera ejecuciones perdidas. En un servidor real (encendido siempre) esto no pasa. Para el proyecto se compensa con **un respaldo manual al final de cada sesión**:

```bash
sudo /usr/local/sbin/respaldo-pixelverde.sh
```

Mejora posible: `anacron` o un timer de systemd con `Persistent=true`, que corren la tarea pendiente al encender.
# Pasos
