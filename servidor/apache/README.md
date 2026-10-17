# servidor/apache — Integrante 2 (HTTPS + proxy inverso)

Aquí van los VirtualHost del **Apache del servidor** (no el del contenedor):

- `pixelverde.conf` → puerto 80, redirige a HTTPS.
- `pixelverde-ssl.conf` → puerto 443 con el certificado autofirmado y
  `ProxyPass / http://127.0.0.1:8080/` + `ProxyPassReverse` + `ProxyPreserveHost On`
  (el mismo patrón del Bloque 5 del Laboratorio 5).
- `PASOS.md` con los comandos exactos.

**Lo que ya quedó listo para esto:**

- El contenedor escucha en `127.0.0.1:8080` (puerto `TYPO3_HTTP_PORT` del `.env`).
- TYPO3 ya acepta el dominio `pixelverde.internal` (`TYPO3_TRUSTED_HOSTS`).
- TYPO3 ya confía en el proxy (`TYPO3_REVERSE_PROXY_IP=172.30.0.1`).
- Cuando HTTPS funcione, solo falta poner en el `.env` del servidor
  `TYPO3_REVERSE_PROXY_SSL=172.30.0.1` y correr `docker compose up -d`.
  Antes de eso, la portada por `pixelverde.internal` da **404** (el sitio se creó con `https://`);
  con esa variable activa responde **200** con la página "Home".
- Las peticiones del proxy llegan al contenedor desde `172.30.0.1` (comprobado en el log de Apache del contenedor).

Los certificados (`.crt`, `.key`) **no** se suben a Git: cada servidor genera los suyos.
