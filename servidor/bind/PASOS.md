# PASOS — DNS (BIND9)

**Encargada:** Elein · **Rol:** DNS y HTTPS (Integrante 2)
**Requisito que cubre:** Común #1 — zona DNS propia (BIND9) para el dominio del proyecto.

Todos los comandos se corren en el **servidor oficial**, dentro de la carpeta del repo (`cd ~/pixelverde`), salvo donde diga `[Mint]`.

---

## 1. Resumen

| Qué | Valor |
|---|---|
| Dominio | `pixelverde.internal` |
| Servidor de nombres | `ns1.pixelverde.internal` → `192.168.50.1` |
| Registro principal | `pixelverde.internal` → `192.168.50.1` (el servidor oficial) |
| Red | La que dejó Karina en `servidor/red/`: IP fija `192.168.50.1/24` en `enp0s8` (intnet), DHCP `.100`–`.130` que entrega `192.168.50.1` como DNS, y NAT por `enp0s3` |

### Archivos del repo y a dónde van

| Archivo del repo | Se copia a |
|---|---|
| `servidor/bind/db.pixelverde.internal` | `/etc/bind/db.pixelverde.internal` |
| `servidor/bind/named.conf.local.pixelverde` | **se agrega al final** de `/etc/bind/named.conf.local` (no lo reemplaza) |

---

## 2. Prerrequisito

BIND9 ya quedó instalado por Karina como resolvedor (ver `PASOS.md` de la raíz, sección 8.4). Si el servidor se reconstruye desde cero:

```bash
sudo apt install -y bind9 bind9-utils dnsutils
sudo systemctl enable --now named
```

---

## 3. Aplicar la zona

```bash
cd ~/pixelverde
git pull

# 1) Archivo de zona
sudo cp servidor/bind/db.pixelverde.internal /etc/bind/

# 2) Declarar la zona (solo la PRIMERA vez; si ya está, no repetir)
grep -q 'pixelverde.internal' /etc/bind/named.conf.local \
  || cat servidor/bind/named.conf.local.pixelverde | sudo tee -a /etc/bind/named.conf.local

# 3) Validar ANTES de reiniciar
sudo named-checkconf
sudo named-checkzone pixelverde.internal /etc/bind/db.pixelverde.internal

# 4) Aplicar
sudo systemctl restart named
sudo systemctl status named --no-pager | head -5
```

**Debe verse:**

```
zone pixelverde.internal/IN: loaded serial 2026102001
OK
```

`named-checkconf` no imprime nada si todo está bien.

> Si se edita la zona, hay que **subir el serial** (la línea `Serial` del SOA, formato `AAAAMMDDnn`) y volver a correr los pasos 3 y 4.

---

## 4. Comprobar

**En el servidor:**

```bash
dig @127.0.0.1 pixelverde.internal +short       # → 192.168.50.1
dig @127.0.0.1 ns1.pixelverde.internal +short   # → 192.168.50.1
dig @127.0.0.1 google.com +short                # sigue resolviendo Internet (resolvedor intacto)
```

**[Mint]** (el Mint ya recibe `192.168.50.1` como DNS por DHCP):

```bash
resolvectl status | grep -i "DNS Server"        # debe aparecer 192.168.50.1
dig pixelverde.internal                         # ANSWER SECTION con 192.168.50.1
dig pixelverde.internal +short                  # → 192.168.50.1
```

Si el Mint no usa el DNS del servidor, renovar la conexión:

```bash
sudo nmcli connection down "netplan-enp0s3" && sudo nmcli connection up "netplan-enp0s3"
```

(El nombre de la conexión puede variar: se ve con `nmcli connection show`.)

---

## 5. Evidencia

| # | Captura | Nombre sugerido en Drive (`02 Evidencias/2 DNS y HTTPS`) |
|---|---|---|
| 1 | `dig pixelverde.internal` desde Mint devolviendo `192.168.50.1` | `I2_dig_pixelverde_mint.png` |
| 2 | `named-checkzone` con `OK` | `I2_named_checkzone.png` |

---

## 6. Errores encontrados y cómo se resolvieron

> Completar al aplicarlo en el servidor oficial. Incluir **captura del error antes de corregir**.

| Error | Causa | Solución |
|---|---|---|
| _(pendiente)_ | | |
