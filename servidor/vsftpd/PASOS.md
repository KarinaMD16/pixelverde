# PASOS — Servidor FTP (vsftpd)

**Encargado:** Orlando · **Rol:** FTP y respaldos (Integrante 4)
**Requisito que cubre:** Común #4 — una cuenta FTP por integrante, sin que un usuario pueda borrar o modificar archivos de otro.

Todos los comandos se corren en el **servidor**, dentro de la carpeta del repo (`cd ~/pixelverde`), salvo que diga otra cosa.

---

## 1. Resumen

| Qué | Cómo quedó |
|---|---|
| Servidor | vsftpd 3.0.5 (paquete de Ubuntu), puerto 21, modo pasivo en 40000–40100 |
| Cuentas | `karina`, `elein`, `diana`, `orlando`, `carolina` — shell `/usr/sbin/nologin`, grupo `ftpnodos` |
| Quién puede entrar | Solo esas 5 (lista blanca `/etc/vsftpd.userlist`). Las cuentas de administración quedan fuera |
| Carpeta expuesta | `/srv/ftp/pixelverde` (raíz del chroot, de root, sin escritura) con `compartido/` adentro |
| Protección | `compartido/` con **sticky bit** (`1775`, grupo `ftpnodos`) + `local_umask=022` |

### Archivos del repo y a dónde van

| Archivo del repo | Se copia a |
|---|---|
| `servidor/vsftpd/vsftpd.conf` | `/etc/vsftpd.conf` |
| `servidor/vsftpd/vsftpd.userlist` | `/etc/vsftpd.userlist` |

Las **claves** de las cuentas no están en Git. Cada quien recibe la suya por privado.

---

## 2. Decisiones y por qué

### 2.1 Qué carpeta se expone: `/srv/ftp/pixelverde`

- **No** el volumen `fileadmin` de TYPO3: vive en `/var/lib/docker/volumes/...` (solo root) y sus archivos son del usuario `www-data` del contenedor. Abrirlo por FTP obliga a mezclar permisos y un archivo mal subido puede romper el sitio. Las imágenes entran a TYPO3 por el backend.
- **No** el `/home` de cada usuario: así cada quien queda aislado y no hay material compartido.
- `/srv` es la carpeta que el estándar de Linux (FHS) reserva para "datos que este servidor ofrece".
- **Uso:** intercambiar material del proyecto (logos, imágenes, textos, exportaciones) entre los integrantes del estudio.

### 2.2 Carpeta compartida con sticky bit (y no una subcarpeta por usuario)

| Opción | Resultado |
|---|---|
| Subcarpeta por usuario | Aísla, pero no se comparte nada |
| **Carpeta compartida + sticky bit** (elegida) | Todos ven y suben; **solo el dueño borra o renombra lo suyo** |

El caso es un estudio que comparte material, así que conviene que todos vean lo de todos. Es el mismo mecanismo que protege `/tmp` en Linux.

Dos protecciones juntas:

| Qué se intenta | Qué lo impide |
|---|---|
| Borrar o renombrar un archivo ajeno | Sticky bit en `compartido/` |
| Sobrescribir o modificar un archivo ajeno | `local_umask=022`: lo subido queda `rw-r--r--`, sin escritura para grupo ni otros |

### 2.3 Por qué hay dos carpetas (`pixelverde/` y `compartido/`)

vsftpd **se niega a usar una raíz de chroot donde el usuario puede escribir** (`500 OOPS: vsftpd: refusing to run with writable root inside chroot()`). Es una protección de seguridad. Por eso la raíz es de root (`755`) y la escritura va en `compartido/`. **No** se usa `allow_writeable_chroot=YES`, que desactiva esa protección.

### 2.4 Cuentas con `nologin` y lista blanca

- Las cuentas solo necesitan FTP: con shell `/usr/sbin/nologin` no pueden abrir una terminal (mínimo privilegio).
- vsftpd valida con PAM, y `/etc/pam.d/vsftpd` tiene `pam_shells.so`: **rechaza a quien tenga un shell que no esté en `/etc/shells`**. Por eso `nologin` tiene que estar registrado ahí; si no, el FTP responde `530 Login incorrect` aunque la clave esté bien.
- Lista blanca (`userlist_deny=NO`): solo entran los 5 del proyecto. FTP manda la clave **sin cifrar**, así que una cuenta con `sudo` nunca debe usarse por FTP. Un usuario fuera de la lista se rechaza **antes** de que se pida la clave.

---

## 3. Instalación paso a paso

### 3.1 Instalar vsftpd y guardar el original

```bash
sudo apt update
sudo apt install -y vsftpd ftp
sudo cp /etc/vsftpd.conf /etc/vsftpd.conf.orig
```

`ftp` es el cliente de línea de comandos, para probar desde el mismo servidor.

### 3.2 Registrar `nologin` en `/etc/shells`

```bash
grep -qx /usr/sbin/nologin /etc/shells || echo /usr/sbin/nologin | sudo tee -a /etc/shells
grep pam_shells /etc/pam.d/vsftpd          # → auth required pam_shells.so
```

El `grep -qx ... ||` solo agrega la línea si no existe: se puede correr varias veces sin duplicarla.

### 3.3 Grupo y cuentas

```bash
sudo groupadd ftpnodos
for u in karina elein diana orlando carolina; do
  sudo useradd -m -s /usr/sbin/nologin -G ftpnodos "$u"
done
```

Clave de cada cuenta (la pide dos veces):

```bash
sudo passwd karina
sudo passwd elein
sudo passwd diana
sudo passwd orlando
sudo passwd carolina
```

### 3.4 Carpeta expuesta y permisos

```bash
sudo mkdir -p /srv/ftp/pixelverde/compartido
sudo chown root:root /srv/ftp/pixelverde
sudo chmod 755 /srv/ftp/pixelverde
sudo chown root:ftpnodos /srv/ftp/pixelverde/compartido
sudo chmod 1775 /srv/ftp/pixelverde/compartido
```

| Dígito de `1775` | Para quién | Significa |
|---|---|---|
| `1` | — | sticky bit (la `t` de `drwxrwxr-t`) |
| `7` | dueño (root) | leer, escribir, entrar |
| `7` | grupo `ftpnodos` | leer, escribir, entrar → los 5 suben archivos |
| `5` | otros | solo leer y entrar |

### 3.5 Configuración de vsftpd

```bash
sudo cp servidor/vsftpd/vsftpd.conf /etc/vsftpd.conf
sudo cp servidor/vsftpd/vsftpd.userlist /etc/vsftpd.userlist
sudo systemctl restart vsftpd
systemctl is-active vsftpd                  # → active
```

vsftpd no tiene un comando para validar la configuración: si una línea está mal, no arranca. En ese caso: `journalctl -u vsftpd -n 20 --no-pager`.

Para ver qué cambió respecto al de fábrica:

```bash
diff <(grep -vE '^\s*(#|$)' /etc/vsftpd.conf.orig) <(grep -vE '^\s*(#|$)' /etc/vsftpd.conf)
```

---

## 4. Comprobaciones

### 4.1 Cuentas

```bash
for u in karina elein diana orlando carolina; do getent passwd "$u"; id "$u"; done
sudo su - orlando                           # → This account is currently not available.
```

Cada línea de `getent` termina en `/usr/sbin/nologin` y cada `id` muestra `ftpnodos`.

### 4.2 Permisos (sin FTP)

```bash
ls -ld /srv/ftp/pixelverde /srv/ftp/pixelverde/compartido
# drwxr-xr-x root root      /srv/ftp/pixelverde
# drwxrwxr-t root ftpnodos  /srv/ftp/pixelverde/compartido

sudo -u orlando touch /srv/ftp/pixelverde/compartido/de_orlando.txt
sudo -u diana rm -f /srv/ftp/pixelverde/compartido/de_orlando.txt   # → Operation not permitted
sudo -u orlando rm /srv/ftp/pixelverde/compartido/de_orlando.txt    # → funciona
```

La protección está en el **sistema de archivos**, no en vsftpd: si esto funciona, funciona por FTP o por cualquier otro medio.

### 4.3 Por FTP

Preparar un archivo para subir:

```bash
cd /tmp
echo "logo de prueba de Orlando" > logo_orlando.txt
```

`ftp localhost` como **orlando**:

```
pwd                      → Remote directory: /          (chroot)
ls                       → solo "compartido"
cd compartido
put logo_orlando.txt     → 226 Transfer complete
bye
```

`ftp localhost` como **diana**:

```
cd compartido
ls                                      → logo_orlando.txt con dueño orlando, -rw-r--r--
delete logo_orlando.txt                 → 550 Delete operation failed.
rename logo_orlando.txt hackeado.txt    → 550 Rename failed.
put logo_orlando.txt                    → 553 Could not create file.
cd /etc                                 → 550 Failed to change directory.
cd /
mkdir prueba                            → 550 Create directory operation failed.
bye
```

`ftp localhost` como **lando** (o cualquier cuenta fuera de la lista) → `530 Permission denied.` sin pedir clave.

### 4.4 Desde Mint (la prueba por la red)

En el gestor de archivos de Mint: *Archivo → Conectar con el servidor* → `ftp://192.168.50.1`, como `diana`. Abrir `compartido` e intentar borrar `logo_orlando.txt` → **"Error al eliminar"**. Después, como `orlando`, borrar el mismo archivo → funciona.

---

## 5. Errores encontrados

Se encontraron practicando en una VM que ya tenía configuración de los laboratorios. En el servidor oficial (limpio) no deberían aparecer, pero explican por qué los pasos están escritos así.

### Error 1 — `/usr/sbin/nologin` repetido 3 veces en `/etc/shells`

**Causa:** en los labs se agregó con `echo ... >> /etc/shells` varias veces.
**Solución:** no rompe nada, pero se limpia con:

```bash
sudo cp /etc/shells /etc/shells.bak
awk '!visto[$0]++' /etc/shells.bak | sudo tee /etc/shells
```

**Prevención:** el paso 3.2 usa `grep -qx ... ||`, que no duplica.

### Error 2 — `vsftpd.conf` con líneas repetidas del lab: `local_umask=002` le ganaba a `022`

**Síntoma:** `grep` mostraba `write_enable`, `chroot_local_user` y `local_umask` dos veces, una con `local_umask=002`. También quedaban `allow_writeable_chroot=YES` y `user_config_dir` del lab.
**Causa:** vsftpd ya estaba instalado y configurado desde el lab, así que `apt install` no hizo nada. Cuando una opción aparece dos veces, **vsftpd usa la última**: con `002` lo subido quedaría con escritura para el grupo.
**Solución:** se respaldó la versión del lab y se partió del original del paquete:

```bash
sudo cp /etc/vsftpd.conf /etc/vsftpd.conf.lab
cd /tmp && apt download vsftpd && dpkg-deb -x vsftpd_*.deb vsftpd-pkg
sudo cp vsftpd-pkg/etc/vsftpd.conf /etc/vsftpd.conf.orig
```

**Prevención:** el paso 3.5 copia un `vsftpd.conf` completo desde el repo, en vez de editar el que haya en el servidor.

### Error 3 — `output to local-file: ... [anpqy?]?` dentro de `ftp>`

**Causa:** se escribió `ls -l /srv/ftp/...` dentro del cliente FTP. Ahí `ls carpeta archivo` significa "guardar el listado en un archivo **local**".
**Solución:** responder `n`, salir con `bye` y correr el `ls` en la terminal.

### Error 4 — El listado FTP mostraba números (`1009`, `1008`) en vez de nombres

**Causa:** dentro del chroot vsftpd no lee `/etc/passwd`, y por defecto muestra UID/GID.
**Solución:** `text_userdb_names=YES` (ya está en el `vsftpd.conf` del repo).

### Nota — `chroot_local_user=YES` aparecía dos veces al editar el original con `sed`

El `vsftpd.conf` de fábrica trae esa línea comentada **dos veces** (una dentro del ejemplo de `chroot_list`). Las dos decían `YES`, así que no cambiaba nada. El archivo del repo la tiene una sola vez.

---

## 7. Mejora posible (trade-off)

FTP manda usuario y clave **sin cifrar** por la red. En la red interna del proyecto se acepta, pero en producción convendría FTPS (`ssl_enable=YES` con un certificado) o SFTP. Se dejó sin cifrar para mantener el mismo esquema del laboratorio y que cualquier cliente (incluido el gestor de archivos de Mint) se conecte sin configuración extra.
# Pasos
