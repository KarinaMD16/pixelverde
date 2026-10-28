
# Instalación nativa de TYPO3 y comparación con Docker — Pixel Verde

**Curso:** EIF431O — Administración de Servidores basados en Software Libre  
**Grupo:** Nodos  
**Escenario:** 6 — Estudio Pixel Verde  
**Responsable:** María Carolina González Jiménez

**Estado:** Instalación nativa comprobada; instalación local con Docker comprobada; comparación con el servidor oficial pendiente de validación.

---

## 1. Objetivo

Instalar TYPO3 directamente en Ubuntu Server, documentar las verificaciones y dificultades técnicas, y comparar este enfoque con la implementación oficial basada en Docker Compose.

La instalación nativa se realiza para el análisis comparativo. La entrega principal del grupo sigue siendo la infraestructura contenerizada.

## 2. Entorno de instalación nativa

| Elemento | Configuración comprobada |
|---|---|
| Máquina virtual | PixelVerde-Nativo, Oracle VirtualBox |
| Sistema operativo | Ubuntu 26.04 LTS |
| Recursos de VM | 4 GB RAM, 2 CPU, 30 GB de disco, red NAT |
| Servidor web | Apache 2.4.66 |
| PHP | 8.5.4 |
| Base de datos | MariaDB 11.8.6 |
| Composer | 2.9.5 |
| CMS | TYPO3 14.3.9 |
| Carpeta del proyecto | `/var/www/pixelverde` |
| Directorio público | `/var/www/pixelverde/public` |
| Base de datos | `pixelverde` |
| Usuario de base de datos | `typo3user` |

La administración se realizó desde CMD de Windows utilizando SSH con reenvío de puertos en VirtualBox.

**Nota de seguridad:** No registrar contraseñas ni claves en este archivo.

---

## 3. Procedimiento realizado en Ubuntu Server

### 3.1. Preparación y conexión

1. Se creó la máquina virtual `PixelVerde-Nativo` en VirtualBox.
2. Se instaló Ubuntu Server y se preparó la conectividad NAT.
3. Se habilitó el acceso SSH desde Windows.
4. Se verificó el sistema operativo y la disponibilidad de los servicios durante la configuración.

Con el reenvío de puertos configurado en VirtualBox se utilizó:

```bash
ssh -p 2222 carolina@127.0.0.1
```

### 3.2. Instalación de Apache y PHP

Se instalaron Apache, PHP y las extensiones requeridas por TYPO3.

Para comprobar las versiones y el estado del servicio se ejecutaron:

```bash
apache2 -v
php -v
sudo systemctl status apache2
```

Para publicar TYPO3 se configuró el VirtualHost ubicado en:

```text
/etc/apache2/sites-available/pixelverde.conf
```

El directorio de publicación se estableció en:

```text
/var/www/pixelverde/public
```

Durante el diagnóstico se revisaron las directivas de acceso del directorio, incluida `AllowOverride All`.

Posteriormente, se validó la sintaxis de Apache mediante:

```bash
sudo apache2ctl configtest
```

### 3.3. Instalación y configuración de MariaDB

Se instaló y verificó MariaDB como gestor de base de datos.

Se creó la base de datos `pixelverde` y el usuario `typo3user`, al cual se le asignaron permisos sobre la base de datos.

También se comprobó que el usuario pudiera establecer una conexión correctamente.

Para verificar el servicio se utilizaron:

```bash
sudo systemctl status mariadb
mariadb --version
```

Las contraseñas reales se mantienen fuera del repositorio.

### 3.4. Instalación de Composer y TYPO3

Se instaló Composer y se preparó el proyecto TYPO3 en el directorio `/var/www/pixelverde`, incluyendo sus dependencias.

Se verificó Composer mediante:

```bash
composer --version
```

Posteriormente, se ejecutó el asistente inicial de TYPO3:

```bash
cd /var/www/pixelverde
./vendor/bin/typo3 setup
```

Durante este procedimiento se configuró la conexión con MariaDB y se creó una cuenta administrativa inicial.

La instalación reportó TYPO3 14.3.9.

### 3.5. Acceso desde Windows y comprobación

Para abrir el sitio desde el navegador de Windows se utilizó un túnel SSH en una ventana independiente:

```bash
ssh -N -L 8081:127.0.0.1:80 -p 2222 carolina@127.0.0.1
```

Se comprobó la respuesta HTTP del servidor y el acceso mediante:

http://localhost:8081/

Después de resolver los problemas de Apache, el sitio respondió con **HTTP 200 OK**.

El primer usuario administrador no permitió iniciar sesión. Por esta razón, se creó una cuenta administrativa de recuperación utilizando el asistente interactivo:

```bash
cd /var/www/pixelverde
./vendor/bin/typo3 backend:user:create --admin
```

Con esta cuenta se logró acceder al panel administrativo:

http://localhost:8081/typo3/

Se verificó el acceso a los módulos de administración de TYPO3.

No se incluyen credenciales en esta documentación.

---

## 4. Incidencias y resultados

Durante la instalación nativa se presentaron dificultades técnicas que requirieron diferentes procedimientos de diagnóstico.

| Incidencia | Acciones realizadas | Resultado |
|---|---|---|
| Error HTTP 500 por directivas de `.htaccess` | Revisión de registros, configuración del VirtualHost y comprobación de Apache | Página pública accesible con HTTP 200 |
| Error de sesiones de la herramienta de instalación | Revisión de propietarios, permisos y pruebas de escritura como `www-data` | Sin causa definitiva identificada; no impidió validar el panel administrativo |
| Inicio de sesión fallido del administrador inicial | Revisión de usuarios y uso de `backend:user:create --admin` | Acceso administrativo recuperado mediante una cuenta adicional |
| Error de correo `Unable to write bytes on the wire` | Revisión de registros y configuración de correo | Envío no completado; incidencia pendiente |

Las verificaciones realizadas permitieron identificar problemas relacionados con la configuración del servidor web, los permisos de archivos y el acceso administrativo.

Aunque algunas incidencias permanecieron sin una solución definitiva, se logró comprobar el funcionamiento de la página pública y del panel administrativo de TYPO3.

---

## 5. Prueba de reproducibilidad en Windows con Docker Desktop

Para comprobar que el repositorio puede ejecutarse en otra máquina, se utilizó Windows con Docker Desktop 29.7.2, sin crear una máquina virtual adicional.

### 5.1. Obtención y configuración del proyecto

Primero se verificó la instalación de Docker:

```cmd
docker --version
docker run --rm hello-world
```

Después se descargó el repositorio oficial del equipo:

```cmd
cd /d "%USERPROFILE%\OneDrive\Escritorio"
git clone https://github.com/KarinaMD16/pixelverde.git
cd pixelverde
```

Se creó el archivo de configuración local:

```cmd
copy .env.example .env
```

En el archivo `.env` se configuraron contraseñas locales propias y se ajustó `TYPO3_SITE_URL` para realizar la prueba en Windows.

**Importante:** El archivo `.env` contiene información sensible y no debe incorporarse al repositorio de GitHub.

### 5.2. Inicio y comprobación de los contenedores

Se comprobó la configuración de Docker Compose:

```cmd
docker compose config --quiet
```

Posteriormente, se construyeron e iniciaron los servicios:

```cmd
docker compose up -d --build
```

Se verificó el estado mediante:

```cmd
docker compose ps
```

**Resultados observados:**

- La imagen `pixelverde/typo3:14.3.9` se construyó correctamente.
- MariaDB utilizó la imagen `mariadb:10.11`.
- Se crearon la red interna y cuatro volúmenes con nombre.
- El contenedor `pixelverde-db` apareció en estado `healthy`.
- El contenedor `pixelverde-typo3` apareció en estado `Up`.
- Se logró acceder al panel administrativo desde Windows.

**Dirección utilizada:**

http://localhost:8080/typo3/

El ingreso se realizó utilizando las credenciales administrativas configuradas para el entorno local.

### 5.3. Verificación de versiones

Se ejecutaron los siguientes comandos:

```cmd
git log -1 --oneline
docker compose images
docker compose exec typo3 php -v
docker compose exec -u www-data typo3 ./typo3/sysext/core/bin/typo3 --version
docker compose exec db mariadb --version
```

Los resultados obtenidos fueron:

| Comprobación | Resultado en Windows |
|---|---|
| Commit de Git | `f2b3a19` (main, mensaje: Pasos TYPO3) |
| Imagen TYPO3 | `pixelverde/typo3:14.3.9` |
| Imagen MariaDB | `mariadb:10.11` |
| PHP | 8.4.27 |
| TYPO3 | 14.3.9 |
| MariaDB | 10.11.19 |
| Arquitectura de imágenes | linux/amd64 |

Al finalizar las comprobaciones se detuvieron los contenedores utilizando:

```cmd
docker compose stop
```

Este procedimiento conservó los contenedores y volúmenes de Docker.

### 5.4. Comparación pendiente con el servidor oficial

Para completar la prueba exigida por el escenario, debe ejecutarse la misma secuencia de comandos en el servidor oficial del equipo.

Es necesario comparar los resultados de ambas máquinas y confirmar:

- El mismo commit del repositorio.
- Las mismas versiones principales de PHP.
- La misma versión de TYPO3.
- Versiones equivalentes de MariaDB.
- Funcionamiento correcto de los servicios.

El identificador interno de la imagen puede variar cuando cada equipo construye su propia imagen.

**Estado actual:** El entorno en Windows funciona y está documentado. Todavía no se han incorporado los resultados del servidor oficial de Karina.

Por lo tanto, la comparación entre las dos máquinas permanece pendiente de validación.

---

## 6. Comparación entre instalación nativa y Docker

La instalación nativa y la instalación mediante Docker permitieron ejecutar TYPO3 utilizando enfoques diferentes.

| Aspecto | Instalación nativa en Ubuntu | Docker Compose |
|---|---|---|
| Instalación | Configuración individual de Apache, PHP, MariaDB y TYPO3 | Servicios declarados en el repositorio y administrados con Compose |
| Versiones observadas | PHP 8.5.4, MariaDB 11.8.6 y TYPO3 14.3.9 | PHP 8.4.27, MariaDB 10.11.19 y TYPO3 14.3.9 en Windows |
| Reproducción | Requiere repetir instalaciones y configuraciones | Facilita replicar servicios e imágenes utilizando la misma configuración |
| Persistencia | Datos almacenados en el sistema y en la base de datos instalada | Volúmenes persistentes de Docker |
| Diagnóstico | Revisión directa de servicios, archivos y registros de Ubuntu | Revisión de contenedores, Compose, redes, volúmenes y registros |
| Ventaja principal | Aprendizaje y control directo del servidor | Mayor facilidad para reproducir entornos consistentes |
| Limitación principal | Más configuración manual y posibles diferencias entre sistemas | Requiere administrar imágenes, variables, volúmenes y redes correctamente |

### 6.1. Análisis de la comparación

La instalación nativa permitió conocer directamente la configuración de los servicios necesarios para ejecutar TYPO3.

Durante este procedimiento se presentaron problemas que requirieron revisar archivos de configuración, registros y permisos del sistema operativo.

Por otra parte, Docker permitió iniciar TYPO3 y MariaDB mediante servicios definidos en Docker Compose.

La utilización de imágenes con versiones específicas facilitó la preparación del entorno local en Windows.

Sin embargo, Docker también requiere administrar correctamente los volúmenes, las variables de entorno y la configuración de los servicios.

### 6.2. Conclusión de la comparación

Para el problema planteado por Pixel Verde, relacionado con las diferencias entre equipos de desarrollo, Docker Compose resulta más adecuado como solución principal.

La instalación nativa permitió comprender las dependencias y las dificultades de configuración manual.

La implementación con Docker, por su parte, facilitó la ejecución del proyecto en otra computadora utilizando los archivos del repositorio.

La demostración definitiva de equivalencia entre ambas máquinas de Docker quedará completada cuando se contrasten los resultados del entorno Windows con los del servidor oficial.

---

## 7. Evidencias

Las capturas de pantalla se encuentran almacenadas en Google Drive del grupo, dentro de la carpeta `02 Evidencias`.

### 7.1. Instalación nativa

**Carpeta:** `5 Instalacion nativa`

Incluye evidencias de:

- Configuración de Ubuntu Server.
- Instalación y verificación de Apache.
- Instalación y verificación de PHP.
- Creación de la base de datos MariaDB.
- Instalación de Composer.
- Instalación y configuración de TYPO3.
- Acceso a la página principal.
- Acceso al panel administrativo.

### 7.2. Prueba de reproducibilidad

**Carpeta:** `7 Prueba de reproducibilidad`

Incluye evidencias de:

- Verificación de Docker Desktop en Windows.
- Clonación del repositorio.
- Construcción e inicio de contenedores.
- Comprobación del estado de los servicios.
- Acceso al administrador de TYPO3.
- Verificación de versiones de Docker, PHP, TYPO3 y MariaDB.

### 7.3. Registro de incidencias

**Carpeta:** `Errores`

Contiene capturas y registros relacionados con las dificultades encontradas durante la instalación.

**Nota de seguridad:** Las capturas se conservan en Google Drive. No se incorporan al repositorio contraseñas, archivos `.env`, certificados privados ni respaldos con información sensible.

---

## 8. Estado final

### Actividades completadas

- Instalación nativa de TYPO3 en Ubuntu Server.
- Configuración de Apache, PHP y MariaDB.
- Acceso a la página pública y al panel administrativo de TYPO3.
- Clonación del repositorio oficial en Windows.
- Ejecución de TYPO3 y MariaDB mediante Docker Desktop.
- Comprobación de las versiones del entorno local.
- Organización de evidencias en Google Drive.
- Documentación de las incidencias técnicas encontradas.

### Actividades pendientes

- Comparar los resultados del servidor oficial de Karina con los obtenidos en Windows.
- Confirmar que ambos equipos utilizan el mismo commit y versiones equivalentes.
- Incorporar las evidencias finales de reproducibilidad.
- Conservar documentadas las incidencias de la instalación nativa que permanecieron sin solución definitiva.

**Resultado general:** Se comprobó el funcionamiento de TYPO3 tanto en la instalación nativa como en el entorno Docker de Windows. La comparación definitiva entre las dos máquinas que ejecutan Docker está pendiente de las evidencias del servidor oficial.
