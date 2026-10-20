# PASOS — HTTPS y proxy inverso (Apache del servidor)

**Encargada:** Elein · **Rol:** DNS y HTTPS (Integrante 2)
**Requisito que cubre:** Común #2 — VirtualHost con HTTPS (certificado propio) sobre la plataforma contenerizada.

Todos los comandos se corren en el **servidor oficial**, dentro de `~/pixelverde`, salvo donde diga `[Mint]`.

**Depende de:** el contenedor TYPO3 respondiendo en `127.0.0.1:8080` (Karina) y la zona DNS de `servidor/bind/` aplicada.

---

## 1. Resumen

```
Mint ──► https://pixelverde.internal ──► Apache del servidor (80/443)
                                              │  proxy inverso
                                              ▼
                                   127.0.0.1:8080 ──► contenedor TYPO3 ──► contenedor MariaDB
```

| Qué | Valor |
|---|---|
| Certificado | Autofirmado, `CN=pixelverde.internal` + SAN `DNS:pixelverde.internal`, 365 días |
| Puerto 80 | Redirección permanente (301) a HTTPS |
| Puerto 443 | HTTPS + `ProxyPass` al contenedor + header `X-Forwarded-Proto: https` |
| Llave privada | `/etc/ssl/private/pixelverde.key`. **Nunca** va a Git (el `.gitignore` bloquea `*.key`, `*.crt`, `*.pem`) |

### Archivos del repo y a dónde van

| Archivo del repo | Se copia a |
|---|---|
| `servidor/apache/pixelverde.conf` | `/etc/apache2/sites-available/pixelverde.conf` |
| `servidor/apache/pixelverde-ssl.conf` | `/etc/apache2/sites-available/pixelverde-ssl.conf` |

---

## 2. Instalar Apache y activar módulos

El servidor oficial es una VM limpia: Apache **no** viene instalado.

```bash
sudo apt install -y apache2
sudo a2enmod ssl proxy proxy_http headers
```

---

## 3. Generar el certificado autofirmado

```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/pixelverde.key \
  -out /etc/ssl/certs/pixelverde.crt \
  -subj "/CN=pixelverde.internal" \
  -addext "subjectAltName=DNS:pixelverde.internal"

sudo chmod 600 /etc/ssl/private/pixelverde.key
openssl x509 -in /etc/ssl/certs/pixelverde.crt -noout -subject -ext subjectAltName
```

**Debe verse:** `subject=CN = pixelverde.internal` y `DNS:pixelverde.internal`.

> El SAN se incluye porque los navegadores modernos validan el nombre contra el SAN y no solo contra el CN.

---

## 4. Instalar y activar los VirtualHost

```bash
cd ~/pixelverde
git pull

sudo cp servidor/apache/pixelverde.conf servidor/apache/pixelverde-ssl.conf /etc/apache2/sites-available/
sudo a2ensite pixelverde pixelverde-ssl
sudo apache2ctl configtest                   # → Syntax OK
sudo systemctl reload apache2
sudo apache2ctl -S                           # VirtualHost 80 y 443 de pixelverde.internal
```

(El aviso `Could not reliably determine the server's fully qualified domain name` es inofensivo. Se quita con `echo "ServerName pixelverde.internal" | sudo tee /etc/apache2/conf-available/servername.conf && sudo a2enconf servername`.)

---

## 5. Que TYPO3 genere URLs con https

El contenedor ya sabe aceptar el dominio y confiar en el proxy (`config/additional.php`, lo dejó Karina). Falta activar la variable de HTTPS en el `.env` **del servidor oficial**:

```bash
cd ~/pixelverde
sed -i 's/^TYPO3_REVERSE_PROXY_SSL=.*/TYPO3_REVERSE_PROXY_SSL=172.30.0.1/' .env
docker compose up -d
```

| Ajuste de TYPO3 | Dónde está | Valor |
|---|---|---|
| `trustedHostsPattern` | `TYPO3_TRUSTED_HOSTS` en `.env` | incluye `pixelverde\.internal` |
| `reverseProxyIP` | `TYPO3_REVERSE_PROXY_IP` en `.env` | `172.30.0.1` (puerta de enlace de la red Docker, de donde llegan las peticiones de Apache) |
| `reverseProxySSL` | `TYPO3_REVERSE_PROXY_SSL` en `.env` | `172.30.0.1` |

Antes de este cambio `https://pixelverde.internal` da **404**; después responde **200** con la página "Home".

---

## 6. Comprobar

**[Mint]:**

```bash
curl -I http://pixelverde.internal           # → HTTP/1.1 301 ... Location: https://pixelverde.internal/
curl -skI https://pixelverde.internal        # → HTTP/1.1 200 OK
```

En el navegador: `https://pixelverde.internal` → aparece la advertencia del certificado (es lo esperado con un certificado autofirmado) → *Avanzado / Aceptar el riesgo* → carga el portafolio.

**Solo el Apache del servidor debe ser accesible desde la red** (el contenedor escucha únicamente en `127.0.0.1`):

```bash
# [Mint] debe FALLAR:
curl -m 3 http://192.168.50.1:8080/
```

### Probar antes de tener TYPO3 (opcional)

Para validar certificado, redirección y proxy en una VM sin Docker, se puede simular el contenedor:

```bash
python3 -m http.server 8080 --bind 127.0.0.1
```

y repetir las pruebas de arriba (el 200 vendrá de ese servidor de prueba). Se apaga con `Ctrl+C`.

---

## 7. Evidencia

| # | Captura | Nombre sugerido en Drive (`02 Evidencias/2 DNS y HTTPS`) |
|---|---|---|
| 1 | `sudo apache2ctl -S` con los VirtualHost 80 y 443 | `I2_apache2ctl_S.png` |
| 2 | Navegador en Mint con `https://pixelverde.internal`, el dominio y la advertencia del certificado visibles | `I2_https_advertencia_mint.png` |
| 3 | `curl -I http://pixelverde.internal` devolviendo 301 hacia https | `I2_curl_301.png` |
| 4 | El portafolio cargando por https tras activar `TYPO3_REVERSE_PROXY_SSL` | `I2_https_typo3_200.png` |

(La captura de `dig` desde Mint está en `servidor/bind/PASOS.md`.)

---

## 8. Justificación: proxy inverso al frente y no HTTPS dentro del contenedor

El enunciado permite las dos opciones y pide justificar la elegida. Se eligió **Apache del servidor como proxy inverso con HTTPS**:

1. **El contenedor queda idéntico en cualquier máquina.** La prueba central del escenario es que el mismo `docker-compose.yml` levante un entorno igual en dos computadoras. Si el certificado viviera dentro del contenedor, cada máquina necesitaría su propio certificado montado o incluido en la imagen, y eso rompe la reproducibilidad.
2. **La llave privada nunca entra a la imagen ni a Git.** Se genera en el servidor y solo la lee Apache. Una imagen con la llave adentro se puede copiar y publicar por accidente.
3. **Un único punto de entrada.** Apache atiende 80 y 443, y el contenedor solo escucha en `127.0.0.1:8080`, así que desde la red solo se llega pasando por HTTPS. Los puertos que publica Docker se saltan `ufw`, por eso se publican solo en localhost.
4. **Reutiliza lo que ya se practicó** en los laboratorios (VirtualHost, `a2enmod`, proxy) y deja al contenedor simple.
5. **Facilita el bonus de alta disponibilidad:** el mismo Apache puede convertirse en balanceador entre dos contenedores sin tocar el DNS ni el certificado.

**Costos (trade-offs):**

- Hay un servicio más que instalar y mantener (Apache) fuera de Docker, así que el servidor no se reconstruye solo con `docker compose up`; hace falta seguir los `PASOS.md`.
- Hay un salto extra de red (Apache → contenedor).
- TYPO3 debe saber que está detrás de un proxy (`reverseProxyIP`, `reverseProxySSL`); si no, genera enlaces `http://` y el backend se ve roto.
- El certificado autofirmado hace que el navegador muestre advertencia; en un caso real se usaría una CA (por ejemplo Let's Encrypt).

---

## 9. Errores encontrados y cómo se resolvieron

> Completar al aplicarlo en el servidor oficial. Incluir **captura del error antes de corregir**.

| Error | Causa | Solución |
|---|---|---|
| _(pendiente)_ | | |
