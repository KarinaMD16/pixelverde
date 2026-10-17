# pixelverde

Infraestructura en contenedores para el sitio de portafolio del Estudio Pixel Verde (TYPO3 + MariaDB, Docker Compose, BIND9, Apache HTTPS). 

Proyecto del curso **EIF431O — Administración de Servidores basados en Software Libre** (UNA, Nicoya). Grupo **Nodos**, escenario 6.

**El problema del estudio:** "funciona en mi máquina pero no en la del otro".
**La solución:** este repositorio. Con un solo `docker compose up` se levanta el mismo TYPO3, con las mismas versiones, en cualquier máquina.

## Qué levanta

| Servicio | Contenedor | Imagen | Puerto |
|---|---|---|---|
| TYPO3 14.3.9 LTS (PHP 8.4 + Apache) | `pixelverde-typo3` | `pixelverde/typo3:14.3.9` (se construye con el `Dockerfile`) | `127.0.0.1:8080` |
| MariaDB 10.11 | `pixelverde-db` | `mariadb:10.11` | ninguno (solo red interna) |

El por qué de cada versión está en [`docs/decisiones.md`](docs/decisiones.md).

## Levantarlo en cualquier máquina (2 minutos + la descarga)

Requisitos: Docker con el plugin Compose (`docker compose version` debe responder).

```bash
git clone <URL-del-repo> pixelverde
cd pixelverde
cp .env.example .env
nano .env                      # cambiar las claves CAMBIAR...
docker compose up -d --build
docker compose logs -f typo3   # esperar "Instalación de TYPO3 terminada." y salir con Ctrl+C
```

Comprobar:

```bash
docker compose ps              # los dos servicios en "Up" (db en "healthy")
docker compose images          # versiones exactas, sin "latest"
curl -I http://localhost:8080/typo3/
```

- Backend: `http://localhost:8080/typo3/` (usuario y clave de `TYPO3_ADMIN_*` en el `.env`).
- El sitio público se ve con el dominio: `https://pixelverde.internal` (cuando el Integrante 2 tenga DNS + HTTPS). Por `localhost` el frontend puede decir que no hay sitio para ese dominio: es normal, el sitio se creó para `pixelverde.internal`.

## Estructura

```
pixelverde/
├── docker-compose.yml      # los dos servicios, volúmenes con nombre, red
├── Dockerfile              # imagen de TYPO3 (PHP 8.4 + Apache + TYPO3 14.3.9)
├── .env.example            # plantilla de claves (el .env real NO se sube)
├── config/
│   ├── php.ini             # valores de PHP recomendados por TYPO3
│   ├── apache-typo3.conf   # Apache del contenedor: permite el .htaccess de TYPO3
│   └── additional.php      # dominio permitido + proxy inverso (lee el .env)
├── docker/
│   └── entrypoint.sh       # instala TYPO3 solo la primera vez y arranca Apache
│   └── sites/              # (reservada) copia de la configuración del sitio TYPO3
├── PASOS.md                # comandos exactos del servidor y contenedores (Integrante 1)
├── servidor/               # configuración del Ubuntu Server oficial
│   ├── red/                # IP fija, DHCP, reenvío y NAT        (Integrante 1)
│   ├── bind/               # DNS pixelverde.internal             (Integrante 2)
│   ├── apache/             # HTTPS + proxy inverso               (Integrante 2)
│   ├── vsftpd/             # FTP                                 (Integrante 4)
│   └── respaldo/           # script de respaldo + cron           (Integrante 4)
└── docs/
    ├── decisiones.md       # justificación de versiones y diseño  (Integrante 1)
    ├── PASOS-typo3.md      # contenido y usuarios de TYPO3         (Integrante 3)
    └── PASOS-nativo.md     # comparación nativo vs. contenedores   (Integrante 5)
```

Las capturas de evidencia van en la carpeta de Google Drive del grupo, no en Git.

## Reglas del repositorio

1. Cada quien trabaja en **su carpeta** y documenta los comandos exactos en un `PASOS.md`.
2. **Nunca** se suben claves, certificados ni respaldos.
3. Antes de empezar a trabajar: `git pull`. Al terminar algo que funciona: `git add`, `git commit -m "..."`, `git push`.
4. Si se cambia `docker-compose.yml` o el `Dockerfile`, debe ser informado al encargado de esa área (Karina).

## Comandos útiles

| Comando | Qué hace |
|---|---|
| `docker compose up -d --build` | Construir (si cambió algo) y levantar |
| `docker compose ps` | Estado de los servicios |
| `docker compose logs -f typo3` | Ver el arranque/errores de TYPO3 (Ctrl+C sale) |
| `docker compose down` | Apagar **sin** borrar datos |
| `docker compose down -v` | Apagar **y borrar los volúmenes** (se pierde todo el contenido) |
| `docker volume ls` | Ver los volúmenes `pixelverde_*` |
| `docker exec -it pixelverde-db mariadb -uroot -p` | Entrar a la base |
