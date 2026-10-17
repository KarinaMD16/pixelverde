# PASOS — Servidor oficial y contenedores

**Encargada:** Karina · **Rol:** contenedores y reproducibilidad

Este archivo tiene dos partes:

- **Parte A — Guía para el grupo:** qué hacer desde cero para empezar a trabajar en el proyecto, qué necesita cada integrante de lo que yo dejé listo y qué hacer si algo falla.
- **Parte B — Lo que hice yo:** resumen de mi parte, cómo se reconstruye el servidor oficial y los errores que encontré.

| Si eres… | Lee |
|---|---|
| Cualquier integrante, primera vez | Secciones [0](#0-antes-de-empezar-una-sola-vez), [1](#1-clonar-el-repositorio) y [2](#2-cada-vez-que-te-sentás-a-trabajar) |
| Integrante 2, 3, 4 o 5 | Además, tu parte de la [sección 3](#3-qué-necesitás-de-lo-mío-según-tu-rol) |
| Quien necesite TYPO3 en su compu | [Sección 4](#4-levantar-typo3-en-tu-compu) |
| Alguien con un error | [Sección 5](#5-si-algo-sale-mal) |


---

# Parte A — Guía para el grupo

## Cómo está organizado el proyecto

- Hay **un solo servidor oficial**: la VM `PIXEL VERDE` en mi laptop. Ahí corre TYPO3 en Docker y ahí se integra todo en las **sesiones presenciales**.
- **Nadie tiene que crear una VM desde cero.** Cada quien trabaja sus archivos en su compu, los sube a Git, y en las sesiones presenciales se aplican en el servidor oficial con `git pull`.
- Git guarda **archivos de configuración y documentación**. No guarda el contenido de TYPO3 (eso vive en la base de datos), ni claves. Las capturas van al **Drive** del grupo.
- Cada integrante tiene **su carpeta** y su `PASOS.md`:

| Archivo / carpeta | Dueño |
|---|---|
| `docker-compose.yml`, `Dockerfile`, `.env.example`, `config/`, `docker/`, `servidor/red/`, `PASOS.md`, `docs/decisiones.md` | Karina |
| `servidor/bind/`, `servidor/apache/` | Integrante 2 |
| `docs/PASOS-typo3.md` | Diana |
| `servidor/vsftpd/`, `servidor/respaldo/` | Integrante 4 |
| `docs/PASOS-nativo.md` | Integrante 5 |

**Regla de oro:** solo editás los archivos de tu carpeta. Si necesitás que cambie algo de otro, se lo pedís a su dueño.


---

## 0. Antes de empezar (una sola vez)


### 0.1 Configuración 

**En la VM Ubuntu o Mint:**

```bash
sudo apt update && sudo apt install -y git
git --version
```

### 0.2 Decirle a Git quién sos

Esto es la **firma** de tus commits: así aparece tu nombre en el historial y cuenta como evidencia de tu trabajo. Usa el correo de tu cuenta de GitHub (o el anónimo de *GitHub → Settings → Emails*).

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "correo-de-tu-cuenta-github"
```

### 0.3 Poder subir cambios (autenticación)

- **Desde la VM sin navegador** usar una llave SSH.

```bash
ssh-keygen -t ed25519 -C "tu-nombre-pixelverde"   # Enter a las 3 preguntas
cat ~/.ssh/id_ed25519.pub                         # copiar TODA la línea
```

Pegala en *GitHub → tu foto → Settings → SSH and GPG keys → New SSH key*. Revisar:

```bash
ssh -T git@github.com     # "Hi <usuario>! You've successfully authenticated"
```

El archivo **sin** `.pub` es tu llave privada y nunca se comparte.

---

## 1. Clonar el repositorio


**Desde la VM con llave SSH:**

```bash
cd ~
git clone git@github.com:KarinaMD16/pixelverde.git
cd pixelverde
```

Comprobar que estás en la carpeta correcta y que ves todo:

```bash
git status        # "On branch main ... nothing to commit, working tree clean"
ls                # docker-compose.yml  Dockerfile  PASOS.md  README.md  config  docker  docs  servidor
```

Ubica tu carpeta en la tabla de arriba: ahí vas a trabajar.

---

## 2. Cada vez que vas a trabajar

**1. Traer lo último que subieron los demás (siempre primero):**

```bash
cd pixelverde
git pull
```

**2. Trabajar solo en tus archivos.** Por ejemplo, el Integrante 2 edita `servidor/bind/PASOS.md` o crea `servidor/bind/db.pixelverde.internal`.

**3. Ver qué cambiaste:**

```bash
git status        # lista de archivos modificados o nuevos
git diff          # qué líneas cambiaron
```

**4. Subirlo cuando algo funciona:**

```bash
git add servidor/bind/                       # tu carpeta o tus archivos concretos
git commit -m "DNS: zona pixelverde.internal y archivo de zona"
git push
```

Buenas costumbres:

- Mensajes de commit que digan **qué** hiciste, no "cambios" o "asdf".
- Sube seguido, en pasos chicos. Es más fácil arreglar un problema pequeño.
- En tu `PASOS.md` anota **los comandos exactos** que corriste y los errores con su solución. Puedes seguir el formato de esta guía.
- **Nunca** subas claves, el archivo `.env`, certificados (`.crt`, `.key`) ni respaldos (`.sql`). El `.gitignore` ya los bloquea pero igual revisa `git status` antes de cada commit.

---

## 3. Qué necesitas de lo mío según tu rol

En todos los casos lo **obligatorio** es lo de las secciones 0, 1 y 2 (clonar y trabajar en tu carpeta). Lo que sigue es lo específico de cada rol.

### Integrante 2 — DNS y HTTPS

**Obligatorio:** solo clonar. No necesitás Docker en tu compu.

**Lo que ya está listo en el servidor oficial:**

- BIND9 instalado como resolvedor: Mint ya usa `192.168.50.1` como DNS y resuelve Internet.
- TYPO3 corriendo en `127.0.0.1:8080`, solo accesible desde el propio servidor.
- TYPO3 ya acepta el dominio `pixelverde.internal` y ya confía en el proxy.

**Lo que te toca:**

1. Agregar la zona `pixelverde.internal` en BIND9 (como en la Sesión 7) → archivos en `servidor/bind/`.
2. Certificado autofirmado con `CN=pixelverde.internal` y VirtualHost 443 en el **Apache del servidor** con proxy inverso → archivos en `servidor/apache/`. Las líneas clave del VirtualHost 443:

```apache
ProxyPreserveHost On
ProxyPass        / http://127.0.0.1:8080/
ProxyPassReverse / http://127.0.0.1:8080/
```

Módulos necesarios: `sudo a2enmod ssl proxy proxy_http headers`. Es el mismo patrón del Bloque 5 del Laboratorio 5.

3. Cuando HTTPS funcione, en el servidor oficial:

```bash
cd ~/pixelverde
sed -i 's/^TYPO3_REVERSE_PROXY_SSL=.*/TYPO3_REVERSE_PROXY_SSL=172.30.0.1/' .env
docker compose up -d
```

Antes de ese cambio, `https://pixelverde.internal` da **404**; después responde **200** con la página "Home". Es normal.

**Opcional:** si quieres practicar el proxy en tu propia VM antes de la sesión presencial, necesitas Docker y la [sección 4](#4-levantar-typo3-en-tu-compu).




### Diana (Integrante 3) — Contenido y usuarios de TYPO3

**Obligatorio:** solo clonar, para subir tu `docs/PASOS-typo3.md`. **No necesitas instalar Docker ni nada más.**

- El contenido de TYPO3 se guarda en la base de datos, no en Git. Por eso se carga **directamente en el servidor oficial**, en una sesión presencial.
- Backend: `http://localhost:8080/typo3/` desde el servidor, o `https://pixelverde.internal/typo3/` cuando el Integrante 2 termine. Usuario `admin`; la clave te la paso por el chat del grupo.
- Mientras tanto, prepara textos, imágenes y logo del portafolio en el Drive.
- **Decisión pendiente:** TYPO3 14 trae un tema de ejemplo ("Camino"). Se activa con `TYPO3_DISTRIBUTION` en el `.env` y **solo se aplica en la primera instalación**. Hay que decidirlo antes de cargar contenido.



### Integrante 4 — FTP y respaldos

**Obligatorio:** solo clonar. No necesitas Docker en tu compu.

Datos fijos para tu script:

| Dato | Valor |
|---|---|
| Contenedor de TYPO3 | `pixelverde-typo3` |
| Contenedor de la base | `pixelverde-db` |
| Puerto publicado | `127.0.0.1:8080` (solo el propio servidor) |
| Base de datos / usuario | `typo3` / `typo3` (valores de `DB_NAME` y `DB_USER` en `.env`) |
| Clave de root dentro de `pixelverde-db` | variable `MARIADB_ROOT_PASSWORD` |
| Volúmenes | `pixelverde_datos_db`, `pixelverde_datos_fileadmin`, `pixelverde_datos_typo3conf`, `pixelverde_datos_typo3temp` |
| Red Docker | `pixelverde_interna` (`172.30.0.0/24`, puerta de enlace `172.30.0.1`) |
| URL del sitio creada en la instalación | `https://pixelverde.internal/` |

Respaldo de la base (la clave se lee dentro del contenedor, no se escribe en el script):

```bash
docker exec pixelverde-db sh -c 'mariadb-dump -uroot -p"$MARIADB_ROOT_PASSWORD" --single-transaction typo3' | gzip > /respaldos/typo3_$(date +%F_%H%M).sql.gz
```

Restauración (para tu prueba documentada):

```bash
gunzip -c /respaldos/typo3_FECHA.sql.gz | docker exec -i pixelverde-db sh -c 'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" typo3'
```

Las imágenes del portafolio **no** están en la base: están en el volumen `pixelverde_datos_fileadmin`. Un respaldo completo incluye los dos.

**Opcional:** para probar tu script antes de la sesión presencial, necesitás Docker y la [sección 4](#4-levantar-typo3-en-tu-compu).




### Integrante 5 — Comparación nativo vs. contenedores

**Obligatorio:** clonar **y** tener Docker, porque te toca la **prueba de las dos máquinas** conmigo.

1. Instalar Docker y levantá TYPO3 con la [sección 4](#4-levantar-typo3-en-tu-compu).
2. Correr `docker compose images` en tu compu y en el servidor oficial. Las versiones tienen que coincidir (captura de las dos, lado a lado).
3. Las versiones elegidas y el porqué están en `docs/decisiones.md`; te sirven para tu documento.

---

## 4. Levantar TYPO3 en tu compu

Solo para quien lo necesite (obligatorio para el Integrante 5, opcional para el 2 y el 4).

### 4.1 Instalar Docker

**Windows [PC]:** instalá **Docker Desktop** (docker.com) y dejá activada la opción de WSL 2. Reiniciá si lo pide y abrí Docker Desktop una vez para que arranque.

**Ubuntu o Mint:**

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
exit                       # cerrar sesión y volver a entrar
```

Comprobá en cualquiera de los dos:

```bash
docker run --rm hello-world
docker compose version
```

### 4.2 Crear tu `.env`

Dentro de la carpeta `pixelverde`:

```bash
cp .env.example .env       # en PowerShell: copy .env.example .env
nano .env                  # en Windows: notepad .env
```

Cambiá `DB_ROOT_PASSWORD`, `DB_PASSWORD` y `TYPO3_ADMIN_PASSWORD`. Reglas: solo letras, números y punto. La del admin necesita mayúscula, minúscula, número y símbolo (ej. `Nodos.Pixel2026`).

Definilas **antes** del primer arranque: MariaDB y TYPO3 guardan las claves la primera vez.

### 4.3 Arrancar

```bash
docker compose up -d --build       # la primera vez tarda varios minutos (~1,2 GB)
docker compose logs -f typo3       # esperar "Instalación de TYPO3 terminada." y salir con Ctrl+C
```

### 4.4 Comprobar

```bash
docker compose ps                  # db (healthy) y typo3 en Up
docker compose images              # mariadb 10.11 · pixelverde/typo3 14.3.9
```

Abrí `http://localhost:8080/typo3/` y entrá con `admin` y la clave de tu `.env`.

### 4.5 Apagar y volver a encender

```bash
docker compose down        # apaga SIN borrar datos
docker compose up -d       # vuelve a encender; no reinstala
```




---

## 5. Si algo sale mal

### Problemas con Git

| Síntoma | Qué hacer |
|---|---|
| `! [rejected] main -> main (fetch first)` al hacer `push` | Alguien subió algo antes. `git pull --rebase` y después `git push`. |
| `CONFLICT (content): Merge conflict in archivo` | Abrí el archivo, buscá las marcas `<<<<<<<`, `=======` y `>>>>>>>`, dejá el texto correcto y borrá las marcas. Después `git add archivo` y `git rebase --continue`. Si te perdés, `git rebase --abort` y avisá. |
| `Permission denied (publickey)` | Tu llave SSH no está en GitHub. Repetí la sección 0.4. |
| `remote: Permission to ... denied` / error 403 | No aceptaste la invitación de colaboradora/or (sección 0.1). |
| `fatal: not a git repository` | No estás dentro de la carpeta. `cd pixelverde`. |
| `fatal: pathspec 'X' did not match any files` | El archivo no existe o el nombre está mal (mayúsculas incluidas). Revisá con `ls`. |
| Quiero deshacer cambios de un archivo que **no** subí | `git restore archivo` (vuelve a la última versión subida). |
| Subí el `.env` o una clave por error | `git rm --cached .env`, `git commit -m "Quitar .env"`, `git push` y **cambiar esas claves**: el repo es público. |



### Problemas con Docker / TYPO3

| Síntoma | Qué hacer |
|---|---|
| `permission denied ... docker.sock` | Tu usuario no está en el grupo `docker`: `sudo usermod -aG docker $USER`, `exit` y volver a entrar. |
| `Falta DB_PASSWORD en .env` (o cualquier `Falta ...`) | No creaste o no llenaste el `.env` (sección 4.2). |
| `typo3` muestra `ERROR: 'typo3 setup' falló` en los logs | Casi siempre es la clave del admin, que no cumple la política. Cambiala en `.env` y empezá de cero: `docker compose down -v` y `docker compose up -d`. |
| `address already in use` en el 8080 | Otro programa usa el puerto. Cambiá `TYPO3_HTTP_PORT=8081` en `.env` y `docker compose up -d`. |
| `Trusted host` error en el navegador | Entraste con un nombre o IP que no está en `TYPO3_TRUSTED_HOSTS`. Agregalo en `.env` y `docker compose up -d`. |
| La portada da 404 por `localhost` o `pixelverde.internal` | Normal hasta que el Integrante 2 tenga HTTPS. El backend `/typo3/` sí funciona. |
| `Access denied for user 'root'` al entrar a la base | Usá `docker exec pixelverde-db sh -c 'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD"'`. |
| No sé qué pasa | Mirá los logs: `docker compose logs --tail 50 typo3` y `docker compose logs --tail 50 db`. |

**Empezar TYPO3 de cero en tu compu** (borra el contenido; **nunca** en el servidor oficial sin avisar):

```bash
docker compose down -v
docker compose up -d --build
```




---

# Parte B — Lo que hice yo (Karina como Integrante 1)

## 6. Resumen

| Qué | Resultado |
|---|---|
| Servidor oficial | VM `PIXEL VERDE`, Ubuntu Server 26.04 LTS, usuario `nodos`, servidor `pixelverde` |
| Red base | IP fija `192.168.50.1/24` en `enp0s8`, DHCP (`.100`–`.130`), reenvío permanente, NAT con iptables. Configuración real guardada en `servidor/red/` |
| DNS base | BIND9 instalado como resolvedor (la zona la agrega el Integrante 2) |
| Docker | Docker Engine + Compose instalados con el script oficial |
| Contenedores | TYPO3 14.3.9 LTS (PHP 8.4 + Apache, `Dockerfile` propio con verificación SHA256) + MariaDB 10.11 |
| Datos | 4 volúmenes con nombre: base, `fileadmin`, `typo3conf`, `typo3temp` |
| Instalación | Automática en el primer arranque (`typo3 setup`), con el dominio `https://pixelverde.internal/` |
| Seguridad | Claves solo en `.env` (no se sube); base sin puerto publicado; TYPO3 solo en `127.0.0.1:8080` |

La justificación de cada versión y decisión está en `docs/decisiones.md`.



## 7. Cómo se probó

- `docker compose ps`: `db` en *healthy* y `typo3` en *Up*.
- `docker compose images`: `mariadb:10.11` y `pixelverde/typo3:14.3.9`, sin `latest`.
- Log del contenedor: `✓ Congratulations - TYPO3 Setup is done.`
- Base: `10.11.19-MariaDB` con las tablas de TYPO3 (`be_users`, `be_groups`, ...).
- Backend de TYPO3 abierto desde Mint en `http://192.168.50.1:8080/typo3/` (prueba temporal con `TYPO3_BIND_IP=0.0.0.0`, después se volvió a `127.0.0.1`).
- `docker compose down` / `up -d`: el log dice "TYPO3 ya está instalado ... No se reinstala" y los datos siguen.



## 8. Reconstruir el servidor oficial desde cero

Solo si la VM se daña o hay que rehacerla.

### 8.1 VM en VirtualBox [PC]

| Ajuste | Valor |
|---|---|
| Nombre | `PIXEL VERDE` |
| ISO | Ubuntu Server 26.04 LTS |
| RAM / CPU / Disco | 4096 MB / 2 / 25 GB |
| Adaptador 1 | NAT |
| Adaptador 2 | Red interna `intnet` |

- En la instalación desatendida de VirtualBox, el usuario **no** puede ser `admin` (ver error 1). Se usó `nodos`, servidor `pixelverde`.
- Apagar cualquier otra VM servidor que use `intnet` (dos DHCP en la misma red chocan).

### 8.2 Primer arranque [Servidor]

```bash
sudo whoami                                  # → root
sudo apt update && sudo apt -y upgrade
sudo apt install -y openssh-server git
sudo systemctl enable --now ssh
ip -br a                                     # enp0s3 = 10.0.2.15 · enp0s8 sin IPv4
```

### 8.3 SSH desde Windows (para poder pegar) [PC]

```powershell
"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" controlvm "PIXEL VERDE" natpf1 "ssh,tcp,127.0.0.1,2222,,22"
ssh -p 2222 nodos@127.0.0.1
```

### 8.4 Clonar el repo y aplicar la red guardada [Servidor]

Los archivos de `servidor/red/` son copia de la configuración real del servidor.

```bash
git clone https://github.com/KarinaMD16/pixelverde.git && cd pixelverde
```

IP fija `192.168.50.1/24` en `enp0s8`:

```bash
sudo cp servidor/red/*.yaml /etc/netplan/
sudo chmod 600 /etc/netplan/*.yaml
sudo netplan generate && sudo netplan apply
ip -br a show enp0s8                         # → 192.168.50.1/24
```

BIND9 como resolvedor (Mint resuelve Internet por `192.168.50.1`):

```bash
sudo apt install -y bind9 bind9-utils dnsutils
sudo systemctl enable --now named
dig @192.168.50.1 google.com +short
```

DHCP (rango `.100`–`.130`, gateway y DNS = `192.168.50.1`):

```bash
sudo apt install -y isc-dhcp-server
sudo cp servidor/red/isc-dhcp-server /etc/default/isc-dhcp-server
sudo cp servidor/red/dhcpd.conf /etc/dhcp/dhcpd.conf
sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf
sudo systemctl restart isc-dhcp-server && sudo systemctl enable isc-dhcp-server
```

Reenvío permanente:

```bash
sudo cp servidor/red/99-forward.conf /etc/sysctl.d/99-forward.conf
sudo sysctl --system | grep ip_forward       # → net.ipv4.ip_forward = 1
```

NAT (**antes** de instalar Docker):

```bash
sudo apt install -y iptables-persistent      # IPv4: Sí · IPv6: No
sudo cp servidor/red/rules.v4 /etc/iptables/rules.v4
sudo netfilter-persistent reload
sudo iptables -t nat -S POSTROUTING          # -A POSTROUTING -o enp0s3 -j MASQUERADE
sudo iptables -S FORWARD                     # las 2 reglas enp0s8 <-> enp0s3
```

Después de instalar Docker **no** se vuelve a correr `netfilter-persistent save`: guardaría también las reglas internas de Docker.

Prueba desde Mint:

```bash
sudo nmcli connection down "netplan-enp0s3" && sudo nmcli connection up "netplan-enp0s3"
ip -br a                                     # 192.168.50.1xx
ping -c 3 192.168.50.1 && ping -c 3 8.8.8.8 && ping -c 3 google.com
```

### 8.5 Docker [Servidor]

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
exit                                         # salir y volver a entrar por SSH
```

```bash
groups                                       # aparece docker
docker run --rm hello-world
docker compose version
sudo iptables -S FORWARD                     # siguen las 2 reglas propias + DOCKER-...
```

Desde Mint: `ping -c 3 8.8.8.8` tiene que seguir funcionando.

### 8.6 Levantar TYPO3

Igual que la [sección 4](#4-levantar-typo3-en-tu-compu), dentro de `~/pixelverde` en el servidor.

### 8.7 Acceso de escritura a GitHub (solo quien hace push desde el servidor)

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "correo-de-tu-cuenta-github"
ssh-keygen -t ed25519 -C "servidor-pixelverde"     # Enter a las 3 preguntas
cat ~/.ssh/id_ed25519.pub                           # pegar en GitHub → Settings → SSH and GPG keys
ssh -T git@github.com                               # "Hi <usuario>! You've successfully authenticated"
git remote set-url origin git@github.com:KarinaMD16/pixelverde.git
```



---

## 9. Evidencias de mi parte

| # | Evidencia | Comando |
|---|---|---|
| 1 | Los dos servicios en Up | `docker compose ps` |
| 2 | Versiones exactas, sin `latest` | `docker compose images` |
| 3 | Volúmenes con nombre | `docker volume ls \| grep pixelverde` |
| 4 | Instalación automática | `docker compose logs typo3 \| grep pixelverde` |
| 5 | Persistencia | `docker compose down` → `docker compose up -d` → el log dice "ya está instalado ... No se reinstala" |
| 6 | Backend desde Mint (prueba temporal) | En `.env`: `TYPO3_BIND_IP=0.0.0.0` → `docker compose up -d` → Mint: `http://192.168.50.1:8080/typo3/` → volver a `127.0.0.1` |
| 7 | Prueba de las dos máquinas (con Integrante 5) | Sección 4 en otra compu + `docker compose images` lado a lado |

Las capturas están en la carpeta de Drive del grupo.



---

## 10. Errores encontrados

### Error 1 — `Username is reserved by the system: admin`

**Síntoma:** la instalación se detuvo con `finish: subiquity/Identity/load_autoinstall_data: Username is reserved by the system: admin` y `An error occurred. Press enter to start a shell`.

**Causa:** la VM se creó con la **instalación desatendida** de VirtualBox y en el usuario se puso `admin`, que ya existe como grupo del sistema en Ubuntu.

**Solución:** `reboot` en esa consola y repetir la instalación con otro usuario (`nodos`). El administrador de TYPO3 sí puede llamarse `admin`: es otro usuario, no tiene relación con Linux.

### Error 2 — No aparecieron las pantallas del instalador (OpenSSH, red, snaps)

**Síntoma:** la instalación terminó sin preguntar nada y no hubo dónde marcar *Install OpenSSH server*.

**Causa:** la instalación desatendida responde todo con los datos de VirtualBox.

**Solución:** instalarlo después:

```bash
sudo apt install -y openssh-server
sudo systemctl enable --now ssh
```

### Error 3 — Mensajes `watchdog: BUG: soft lockup - CPU#0 stuck` durante la instalación

**Síntoma:** en el paso `downloading and installing security updates` aparecieron esos mensajes y el instalador tardó mucho.

**Causa:** la VM se quedó sin CPU unos segundos porque la PC estaba ocupada con otros programas. No es una falla de la instalación.

**Solución:** esperar (o *Cancel update and reboot*) y cerrar programas pesados. Las actualizaciones se aplican después con `sudo apt -y upgrade`.

### Error 4 — `ssh: connect to host 127.0.0.1 port 2222: Connection refused`

**Causa:** la regla de reenvío de puertos del Adaptador NAT no quedó creada.

**Solución:** crearla por comando con la VM encendida (sección 8.3) y comprobar con `netstat -ano | findstr :2222` (debe salir `LISTENING`).

### Error 5 — `Could not find a registered machine named 'PIXEL VERDE, SERVER'`

**Causa:** la VM se había renombrado a `PIXEL VERDE`; `VBoxManage` necesita el nombre exacto.

**Solución:** usar el nombre actual (se ve con `VBoxManage list vms`).

### Error 6 — `FINDSTR: No se puede abrir #`

**Causa:** se pegó un comando con comentario (`# ...`) en la terminal de Windows. En `cmd` el `#` no es comentario, así que tomó esas palabras como nombres de archivo.

**Solución:** en Windows escribir solo el comando: `netstat -ano | findstr :2222`.

### Error 7 — `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`

**Causa:** Windows tenía guardada la huella de la VM de los labs para `[127.0.0.1]:2222`, y ahora en ese puerto responde la VM nueva.

**Solución:** borrar la huella vieja y aceptar la nueva (no afecta a ninguna VM):

```powershell
ssh-keygen -R "[127.0.0.1]:2222"
ssh -p 2222 nodos@127.0.0.1                  # responder yes
```

Si después se vuelve a usar la VM de los labs en el mismo puerto, pasa lo mismo al revés. Para evitarlo, usar otro puerto (ej. `2223`) para una de las dos.

### Error 8 — Docker instalado, pero el usuario no estaba en el grupo `docker`

**Síntoma:** `get-docker.sh` terminó bien (Client y Server), pero `groups` no mostraba `docker`.

**Causa:** faltó `sudo usermod -aG docker $USER` después del script.

**Solución:**

```bash
sudo usermod -aG docker $USER
exit                                         # volver a entrar
groups                                       # ahora aparece docker
```

### Error 9 — `yaml: construct errors: ... mapping key "name" already defined at line 11`

**Síntoma:** `docker compose config` reportó `name`, `services`, `volumes` y `networks` repetidos.

**Causa:** el contenido del `docker-compose.yml` se pegó **dos veces** en nano (la primera copia quedó incompleta).

**Solución:** vaciar el archivo y pegarlo una sola vez:

```bash
: > docker-compose.yml
nano docker-compose.yml
grep -c "^name:" docker-compose.yml          # → 1
docker compose config --quiet && echo "Sintaxis OK"
```

### Error 10 — `fatal: pathspec 'Dockerfile' did not match any files`

**Causa:** el archivo `Dockerfile` no se había creado. Además, `git add` no agrega **ninguno** de los archivos si uno solo de la lista no existe.

**Solución:** crearlo con ese nombre exacto (D mayúscula, sin extensión), comprobar con `ls -l Dockerfile` y repetir el `git add`.

### Error 11 — `ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: NO)`

**Síntoma:** al revisar la base con `docker exec -it pixelverde-db mariadb -uroot -p -e "..." | head`, después de escribir la clave salió `Access denied ... (using password: NO)`.

**Causa:** el comando terminaba en `| head`. Con la salida redirigida a otro programa, el aviso `Enter password:` no recibió lo escrito y mandó la clave vacía.

**Solución:** leer la clave dentro del contenedor, sin escribirla:

```bash
docker exec pixelverde-db sh -c 'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" -e "SELECT VERSION(); SHOW TABLES FROM typo3;"' | head
```

Resultado: `10.11.19-MariaDB` y las tablas de TYPO3 (`be_users`, `be_groups`, ...).
