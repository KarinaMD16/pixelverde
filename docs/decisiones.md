# Decisiones técnicas — Contenedores. Encargada: Karina

Este documento justifica cada versión y cada decisión del `docker-compose.yml` y del `Dockerfile`.

## Versiones elegidas

| Componente | Versión fija | Por qué |
|---|---|---|
| TYPO3 | **14.3.9 LTS** | Es la versión LTS actual para proyectos nuevos (octubre 2026). LTS = soporte de seguridad por 3 años. |
| PHP | **8.4** (`php:8.4-apache`) | TYPO3 14 acepta PHP 8.2 a 8.5. Se elige 8.4: está dentro del rango, es estable y no es la versión más nueva recién salida. |
| Base de datos | **MariaDB 10.11** (`mariadb:10.11`) | TYPO3 14 declara soporte oficial para MariaDB **10.4.3 a 10.99**. La 11.8 que usamos en la Sesión 12 **queda fuera** de ese rango; la 10.11 es una versión LTS de MariaDB que sí está dentro. |
| Servidor web en el contenedor | Apache (viene en `php:8.4-apache`) | TYPO3 trae `.htaccess` listo para Apache; ya lo dominamos del curso. |

Ninguna imagen usa `latest`. 
`docker compose images` muestra las versiones exactas en cualquier máquina.

> Para cambiar de versión de TYPO3 se cambian juntas `TYPO3_VERSION` y `TYPO3_SHA256` en el `Dockerfile`. El SHA256 está en get.typo3.org.

## ¿Por qué un Dockerfile propio y no una imagen ya hecha?

TYPO3 no publica una imagen oficial en Docker Hub. La documentación oficial usa de ejemplo una imagen **comunitaria** (`martinhelmich/typo3`) y la etiqueta como para pruebas locales y aprendizaje.

Se eligió un `Dockerfile` propio porque:

1. **Se parte de imágenes oficiales** (`php` y `mariadb` de Docker Hub), no de un tercero.
2. **Se fija la versión exacta** de TYPO3 (14.3.9) y se **verifica el paquete con SHA256**: si alguien altera la descarga, la construcción falla.
3. **Se ve todo lo que se instala**: extensiones de PHP, módulos de Apache, GraphicsMagick. Eso es justamente lo que pide la comparación nativo vs. contenedores.

Se usa el **modo clásico** de TYPO3 (paquete `.tar.gz`) en lugar de Composer, porque es el mismo tipo de instalación que hicimos con WordPress y Joomla, y no obliga a nadie del grupo a aprender Composer.

## Volúmenes con nombre

| Volumen | Ruta en el contenedor | Qué guarda |
|---|---|---|
| `pixelverde_datos_db` | `/var/lib/mysql` | Toda la base de datos (páginas, usuarios, contenido) |
| `pixelverde_datos_fileadmin` | `/var/www/html/fileadmin` | Imágenes y archivos subidos (portafolio) |
| `pixelverde_datos_typo3conf` | `/var/www/html/typo3conf` | `settings.php`, configuración del sitio, extensiones |
| `pixelverde_datos_typo3temp` | `/var/www/html/typo3temp` | Caché, logs y temporales |

Son **con nombre** y no anónimos por lo que vimos en la clase 12: un volumen anónimo se pierde de vista al recrear el contenedor; uno con nombre se vuelve a montar siempre en la misma ruta y los datos siguen ahí.

## Red y puertos

- La base **no publica** el 3306. Solo `typo3` llega a ella por la red interna `pixelverde_interna`.
- TYPO3 se publica en `127.0.0.1:8080`: solo el propio servidor llega. El Apache del servidor (80/443, ya ocupados) hace de **proxy inverso** con HTTPS (Integrante 2), igual que en el Laboratorio 5.
- La red tiene subred fija `172.30.0.0/24`: la puerta de enlace siempre es `172.30.0.1`, y así TYPO3 puede confiar en el proxy con una IP conocida (`config/additional.php`).

## Credenciales

- Si falta una variable obligatoria, `docker compose` se detiene con un mensaje claro (`Falta ... en .env`) en lugar de arrancar a medias.

## Instalación automática de TYPO3

En el primer arranque, el contenedor ejecuta `typo3 setup` (comando oficial de TYPO3) con los datos del `.env`: base de datos, usuario administrador y sitio con la URL `https://pixelverde.internal/`. 

Ventajas:

- En las dos máquinas de la prueba central la instalación es **idéntica** (mismo comando, mismos datos).
- Se instala con el **dominio**, no con la IP (el error que tuvimos con WordPress y Joomla).

Como los datos quedan en volúmenes, en los arranques siguientes el contenedor detecta que ya está instalado y no reinstala.
