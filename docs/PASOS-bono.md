# PASOS — Bono: alta disponibilidad

**Encargadas:** Karina (contenedores) y Elein (Apache) · **Explicación en el documento:** Integrante 5
**Requisito que cubre:** Bono — al menos dos instancias del mismo servicio sirviendo el mismo sitio, y demostrar que si una cae, la otra responde.

Todos los comandos se corren en el **servidor oficial**, dentro de la carpeta del repo (`cd ~/pixelverde`), salvo donde diga `[Mint]` o `[PC]`.

---

## 1. Resumen

| Qué | Valor |
|---|---|
| Copias de TYPO3 | `typo3` → `127.0.0.1:8080` (route 1) · `typo3-2` → `127.0.0.1:8081` (route 2) |
| Qué comparten | La misma imagen, la misma base (`db`) y los mismos volúmenes (`fileadmin`, `typo3conf`, `typo3temp`) |
| Quién reparte | El Apache del servidor, con `mod_proxy_balancer` (`lbmethod=byrequests`: una visita a cada uno) |
| Si una copia cae | Apache la marca en error y manda todo a la otra. La vuelve a probar cada 10 segundos (`retry=10`) |
| Cómo se ve quién respondió | Encabezado `X-Servido-Por: 1` o `2` en cada respuesta, y la página `https://pixelverde.internal/balancer-manager` |
| Qué NO cambia | DNS, certificado, FTP, respaldos y el contenido de Diana |

```
Mint → https://pixelverde.internal
          ↓
   Apache del servidor (HTTPS + balanceador)
      ↙                ↘
 typo3 (:8080)      typo3-2 (:8081)
      ↘                ↙
   db (MariaDB) + volúmenes compartidos
```

El bono **se agrega encima** de lo obligatorio, sin cambiar ningún archivo existente:

- `docker-compose.yml` queda igual. La segunda copia está en un archivo aparte, `docker-compose.ha.yml`, que solo se usa si el `.env` lo pide.
- `pixelverde-ssl.conf` queda igual. El balanceador es otro VirtualHost, `pixelverde-ssl-ha.conf`, y se activa uno **o** el otro.

Así la prueba de las dos máquinas y la demo obligatoria no se tocan, y el bono se apaga en un minuto (sección 6).

### Archivos del repo y a dónde van

| Archivo del repo | Dueño | Se copia a |
|---|---|---|
| `docker-compose.ha.yml` | Karina | Se queda en `~/pixelverde` (lo lee `docker compose`) |
| `.env.example` (líneas del bono al final) | Karina | Las dos líneas se agregan al `.env` real del servidor |
| `servidor/apache/pixelverde-ssl-ha.conf` | Elein | `/etc/apache2/sites-available/pixelverde-ssl-ha.conf` |

---

## 2. Antes de empezar

**[PC] Snapshot.** Con la VM apagada, tomar una snapshot con el siguiente número de la lista (por ejemplo `06-antes-bono`). Si algo sale mal, se vuelve ahí.

**[Servidor] Versión de Compose.** El archivo del bono usa `!override`, que necesita Compose 2.24 o más nuevo:

```bash
docker compose version                # Docker Compose version v2.24 o mayor
```

**[Servidor] Traer el repo y confirmar que lo obligatorio está bien:**

```bash
cd ~/pixelverde
git switch main
git pull
ls docker-compose.ha.yml servidor/apache/pixelverde-ssl-ha.conf
docker compose ps                     # db (healthy) y typo3 en Up
curl -skI https://pixelverde.internal | head -1   # HTTP/1.1 200 OK
```

---

## 3. Segunda copia de TYPO3 (Karina)

**1. Agregar las líneas del bono al `.env`** (el `.env` no se sube, por eso se hace a mano):

```bash
cd ~/pixelverde
grep -q '^COMPOSE_FILE=' .env || echo 'COMPOSE_FILE=docker-compose.yml:docker-compose.ha.yml' >> .env
grep -q '^TYPO3_HTTP_PORT_2=' .env || echo 'TYPO3_HTTP_PORT_2=8081' >> .env
grep -E 'COMPOSE_FILE|HTTP_PORT' .env
```

**Debe verse:**

```
TYPO3_HTTP_PORT=8080
COMPOSE_FILE=docker-compose.yml:docker-compose.ha.yml
TYPO3_HTTP_PORT_2=8081
```

Con `COMPOSE_FILE`, todos los `docker compose ...` usan los dos archivos sin tener que escribir `-f`.

**2. Levantar:**

```bash
docker compose up -d
docker compose ps
```

**Debe verse:**

```
pixelverde-db        ...  Up ... (healthy)
pixelverde-typo3     ...  Up ... (healthy)   127.0.0.1:8080->80/tcp
pixelverde-typo3-2   ...  Up ...             127.0.0.1:8081->80/tcp
```

`typo3` se recrea una vez (es normal: se le agregó el *healthcheck*). Los datos no se pierden porque están en los volúmenes.

**3. Comprobar que `typo3-2` NO reinstaló:**

```bash
docker compose logs typo3-2 | grep pixelverde
```

**Debe verse:** `TYPO3 ya está instalado (typo3conf/system/settings.php existe). No se reinstala.`

**4. Las dos copias responden lo mismo:**

```bash
curl -s -o /dev/null -w "8080: %{http_code}\n" http://127.0.0.1:8080/typo3/
curl -s -o /dev/null -w "8081: %{http_code}\n" http://127.0.0.1:8081/typo3/
```

**Debe verse:** `8080: 200` y `8081: 200`.

> **Por qué `typo3-2` espera a `typo3`:** en una máquina nueva, si arrancaran juntos, los dos verían que TYPO3 no está instalado e intentarían instalarlo a la vez sobre la misma base. Por eso `docker-compose.ha.yml` le pone un *healthcheck* a `typo3`, y `typo3-2` solo arranca cuando `typo3` ya responde. En el servidor oficial TYPO3 ya está instalado, pero así funciona igual desde cero.

---

## 4. Apache como balanceador (Elein)

**1. Módulos del balanceador** (`ssl`, `proxy`, `proxy_http` y `headers` ya están activos):

```bash
sudo a2enmod proxy_balancer lbmethod_byrequests
```

**2. Cambiar el VirtualHost 443 por la versión con balanceador:**

```bash
cd ~/pixelverde
sudo cp servidor/apache/pixelverde-ssl-ha.conf /etc/apache2/sites-available/
sudo a2dissite pixelverde-ssl
sudo a2ensite pixelverde-ssl-ha
```

Los dos usan el puerto 443 con el mismo nombre: **nunca** deben quedar activos a la vez.

**3. Validar ANTES de recargar:**

```bash
sudo apache2ctl configtest            # Syntax OK
sudo systemctl restart apache2
ls /etc/apache2/sites-enabled/        # pixelverde.conf  pixelverde-ssl-ha.conf (sin pixelverde-ssl.conf)
```

Se usa `restart` y no `reload` porque se activaron módulos nuevos.

**4. Comprobar en el servidor:**

```bash
for i in 1 2 3 4; do curl -skI https://pixelverde.internal/ | grep -i x-servido-por; done
```

**Debe verse:** `X-Servido-Por: 1`, `2`, `1`, `2` (alterna).
