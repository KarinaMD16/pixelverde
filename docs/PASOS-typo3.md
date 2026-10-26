
# PASOS — Contenido y usuarios de TYPO3 (Integrante 3)
# original 
**Encargada:** Diana · **Rol:** contenido del portafolio, apariencia y roles de usuario
**Requisitos que cubre:** portafolio real con al menos 4 proyectos · apariencia propia · dos niveles de usuario que se comportan distinto.

Todo se hizo en el **backend de TYPO3** desde el navegador de **Linux Mint** (la VM cliente), entrando a `https://pixelverde.internal/typo3/`. Lo que se hace con clics queda guardado en la **base de datos** y en el volumen **`fileadmin`**, no en Git. Por eso este archivo es la evidencia escrita de lo que se configuró.

Las capturas están en Drive, carpeta `Integrante 3`, con nombre `3TYPO3 y usuarios`.

---

## 0. Antes de empezar

| Dato | Valor |
|---|---|
| Versión | TYPO3 14.3.9 (contenedor `pixelverde-typo3`) |
| Backend | `https://pixelverde.internal/typo3/` (por el proxy HTTPS del Integrante 2) |
| Tema | **Camino**, el tema por defecto de TYPO3 14 |
| Dónde viven las imágenes | `fileadmin/` → volumen `pixelverde_datos_fileadmin` (lo respalda el Integrante 4) |

Se comprobó en el servidor que TYPO3 estuviera detrás del proxy HTTPS:

```bash
cd ~/pixelverde
docker compose ps                                 # db (healthy) y typo3 en Up
grep REVERSE_PROXY_SSL .env                       # TYPO3_REVERSE_PROXY_SSL=172.30.0.1
curl -skI https://pixelverde.internal | head -1   # HTTP/1.1 200 OK
```

Antes de cargar contenido se tomó una instantánea de la VM en VirtualBox.

---

## 1. Material del portafolio

Los textos salen del documento **Textos** (Drive): los 4 proyectos contienen resumen, descripción y "Qué hicimos", más *Sobre nosotros* y *Contáctanos*.

Las imágenes son de **Pexels** y **Unsplash** (licencia libre). Los enlaces originales están al final de ese documento.

| Proyecto | Imágenes |
|---|---|
| Coffee Moon | 1 principal + 3 de galería (Pexels) |
| Biblioteca Comunitaria | 1 principal + 3 de galería (Pexels) |
| Naturaleza en Acción | 1 principal + 3 de galería (Unsplash) |
| Manos de Barro | 1 principal + 2 de galería (Pexels) |

### 1.1 Subir las imágenes al módulo Media

1. **Media** → `fileadmin` → carpeta nueva `proyectos`, y dentro una subcarpeta por proyecto.
2. Carpeta `logo` para el logo del estudio.
3. En cada carpeta, **Upload files**. Límite: 10 MB por archivo (`upload_max_filesize` en `config/php.ini`).

Comprobación en el servidor (las imágenes quedan en el volumen, no en la compu de nadie):

```bash
docker exec pixelverde-typo3 ls -R fileadmin/proyectos fileadmin/logo
```

`I3-C01-media.png` · `I3-C01b-terminal-fileadmin.png`

---

## 2. Apariencia: tema Camino

### 2.1 Activar Camino

**System → Extensions** → buscar `camino` → activar.

### 2.2 Agregar Camino al sitio

**Sites → Setup** → editar el sitio `main` (Entry Point `https://pixelverde.internal/`) → **Sets for this Site** → agregar **Theme: Camino** → **Save** → rayo → **Flush all caches**.

Orden final de los sets (importante, ver error 3):

1. Fluid Styled Content
2. Fluid Styled Content CSS
3. Theme: Camino

`I3-C02b-sitio-main.png` · `I3-C02-sitio-camino.png`

### 2.3 Colores

**Sites → Setup → Edit site settings → Theme Camino → Color Scheme** → **Forest Mist** (el esquema verde, va con el nombre "Pixel Verde").

 `I3-C03-colores.png`

### 2.4 Diseño de las páginas y logo

**Content → Layout → Home → Edit page properties → Appearance**:

| Campo | Valor |
|---|---|
| Backend Layout (this page only) | Camino: Start page |
| Backend Layout (subpages of this page) | Camino: Content page (full-width) |

Logo: en la misma pestaña **Appearance** de Home, campo **Logo** → **Select & upload files** → `fileadmin/logo/pixelverde_logo.png` → **Save**. TYPO3 lo muestra en el encabezado, junto al menú, y en el pie de página.

`I3-C04-logo.png` · `I3-C04b-logo-publico.png`

### 2.5 Estilos propios con CSS

Además del esquema Forest Mist, se subió una hoja de estilos propia (CSS custom)

---

## 3. Páginas, menú y los 4 proyectos

El menú del sitio sale solo del árbol de páginas: cada página que cuelga de Home es un botón del menú.

```text
Home                          (página raíz del sitio)
├── Proyectos
│   ├── Coffee Moon
│   ├── Biblioteca Comunitaria
│   ├── Naturaleza en Acción
│   └── Manos de Barro
├── Sobre nosotros
└── Contacto
```

### 3.1 Crear las páginas

1. Botón **+ Page** arriba del árbol → arrastrar **Standard** sobre la página padre → escribir el título.
2. Las páginas nacen ocultas: clic derecho → **Enable**.
3. Tipo **Standard Page** en todas (una *Folder* no sale en el menú, ver error 4).
4. Títulos sin emojis: TYPO3 arma la dirección con el título (`/proyectos/coffee-moon`).

`I3-C05-arbol.png`

### 3.2 Contenido de cada proyecto

En la página de cada proyecto, en **Content area** → **Create new content** → **Text & Images**:

| Campo | Contenido |
|---|---|
| Header | Nombre del proyecto |
| Subheader | El resumen |
| Text | La descripción y, en párrafo aparte, **Qué hicimos:** con su lista |
| Images | La imagen principal |

### 3.3 Página Proyectos (vitrina)

**Content area** → **Text-Media Teaser Grid** (elemento de Camino) → un ítem por proyecto con imagen, título y **Link** a su página (texto del enlace: "Ver más").

### 3.4 Sobre nosotros y Contacto

Elementos de texto con lo que dice el documento **Textos**: los 3 párrafos del estudio + "Lo que hacemos", y el correo, horario y ubicación.

### 3.5 Revisar el sitio público

Rayo → **Flush frontend caches** → `https://pixelverde.internal`.

📸 `I3-C06-portada.png` · `I3-C07-proyectos.png` · `I3-C08-un-proyecto.png`

Instantánea de la VM: `05-contenido-typo3`.

---

## 4. Dos niveles de usuario

En TYPO3 un grupo solo da lo que se le marca. Por eso se configuran 4 cosas: el grupo, lo que ve (páginas y carpetas), los usuarios y los permisos de cada página.

### 4.1 Montaje de archivos

**Media** → clic derecho en `proyectos` → **New filemount** → `Imagenes de proyectos`.

### 4.2 Grupo "EDITOR DE CONTENIDO"

**Administration → Users** → desplegable **Backend user groups** → **Create new backend user group**.

| Pestaña | Configuración |
|---|---|
| General | Título `EDITOR DE CONTENIDO` · Descripción: "Solo crea y edita páginas y contenido del portafolio, sin acceso a usuarios, extensiones ni configuraciones" |
| Record Permissions → tablas | Page, Page Content, File Reference: **Read & Write** · File, File Metadata: **Read** · todo lo demás: **No Access** |
| Record Permissions → Allowed fields | Page Content y File Reference: todos los campos · Page: ocultar/mostrar |
| Record Permissions → Specific Permissions | Tipos de contenido permitidos: Text & Images, Text & Media, Text, Header, Images, Text-Media Teaser Grid (y los demás que se usen en el sitio) |
| Module Permissions | Content → Layout, Records, Preview · Media. **Nada** de Sites, Administration ni System |
| Mounts | Page Tree Entry Points: **Home** · File Mounts: **Imagenes de proyectos** · archivos: leer, subir, renombrar, reemplazar (sin borrar) |

> En TYPO3 14 la vieja pestaña *Access Lists* se partió en **Record Permissions** y **Module Permissions**, y los *DB Mounts* ahora se llaman **Page Tree Entry Points**.

`I3-C09a-record-permissions.png` · `I3-C09a-record-permissions-2.png` · `I3-C10-mounts.png` · `I3-C10b-editor-media.png`

### 4.3 Grupo "Administrador"

Título `Administrador`, todos los módulos, Page Tree Entry Points: **Home**.

El poder total en TYPO3 no lo da el grupo sino la casilla **Admin** del usuario. El grupo sirve para nombrar el rol.

`I3-C11a-grupos.png`

### 4.4 Usuarios

**Administration → Users** → **Backend users** → **Create new backend user**.

| Campo | Editor | Administrador |
|---|---|---|
| Username | `editor.pixel` | `diana.admin` |
| Name | Editor de prueba | Diana |
| Group | EDITOR DE CONTENIDO | Administrador |
| Admin | **apagado** | **encendido** |
| Mount from groups | Page Tree Entry Points ✓ · File Mounts ✓ | ✓ · ✓ |

Claves: 8+ caracteres con mayúscula, minúscula, número y símbolo (política de TYPO3). Se guardaron en un lugar privado del grupo, no aquí.

`I3-C11b-crear-editor.png` · `I3-C11c-crear-admin.png` · `I3-C11d-admin-mounts.png`

### 4.5 Permisos de las páginas

Cada página tiene dueño, grupo y permisos, como un archivo en Linux. Las páginas las creó el admin, así que hubo que dárselas al grupo Editor.

**Administration → Permissions** → lápiz en **Home**:

| Campo | Valor |
|---|---|
| Group | EDITOR DE CONTENIDO |
| Depth | **Set recursively 2 levels** (7 páginas: las 3 hijas de Home + los 4 proyectos) |

| | Show page | Edit content | Edit page | Delete page | New pages |
|---|---|---|---|---|---|
| Owner | ✓ | ✓ | ✓ | ✓ | ✓ |
| Group (Editor) | ✓ | ✓ | ✓ | **✗** | ✓ |
| Everybody | ✓ | ✗ | ✗ | ✗ | ✗ |

El Editor trabaja el contenido pero **no puede borrar páginas**.

 `I3-C12-permisos-paginas.png`

---

## 5. Prueba: Editor contra Administrador

Ventana normal de Firefox con `diana.admin`, y ventana privada (`Ctrl+Shift+P`) con `editor.pixel`.

| Prueba | Resultado esperado | Captura |
|---|---|---|
| Menú de cada uno | Editor: solo **Content** (Layout, Records, Preview) y **Media**. Admin: además Sites, Administration y System | `I3-C13-editor-vs-admin.png` |
| El Editor edita un proyecto | Abre el elemento, cambia el texto y guarda ("Record saved") | `I3-C14-editor-guarda.png` |
| El Editor abre System → Extensions pegando la dirección | Acceso denegado | `I3-C15-editor-denegado.png` |

---

## 6. Errores encontrados y cómo se resolvieron

### Error 1 — Se borró la página Home y el sitio dio "Page Not Found"

**Qué pasó:** al activar Camino, TYPO3 importó una página de demostración llamada **Camino** (con textos del Camino de Santiago). Se confundió con el sitio real y se borró **Home**, que era la raíz a la que apunta `https://pixelverde.internal`.

**Solución:** **Content → Recycler** → raíz → profundidad infinita → **Home** → **Restore**. Después se borró la página demo *Camino* y su sitio.

**Aprendizaje:** el sitio es la página raíz que creó la instalación. El contenido de demostración no cuenta para la rúbrica y se elimina.

### Error 2 — No aparecía el campo Logo ni los Backend Layouts de Camino

**Qué pasó:** *Theme: Camino* se había agregado al sitio de la demo, no al de Home. Después de agregarlo, TYPO3 seguía mostrando la configuración vieja.

**Solución:** agregar *Theme: Camino* en los sets del sitio `main` → **Flush all caches** → recargar el backend.

`I3-E2-sitio-demo.png` · `I3-E2-colores-demo.png` · `I3-E2-logo-en-demo.png` · `I3-E2-sin-logo-ni-layouts.png`

### Error 3 — "Oops, an error occurred!" en la página Proyectos

**Qué pasó:** la página que tenía el **Text-Media Teaser Grid** mostraba solo el mensaje de error con un código. En el log del contenedor:

```bash
docker exec pixelverde-typo3 sh -c 'grep -h "<código>" /var/www/html/typo3temp/var/log/*.log'
```

```
InvalidTemplateResourceException: FLUIDTEMPLATE TypoScript object:
Failed to resolve a template file for templateName "Default"
... fluid_styled_content/Resources/Private/Templates/ ...
```

**Causa:** los sets del sitio se cargan en orden. *Fluid Styled Content* estaba **después** de *Theme: Camino* y pisaba la configuración de los elementos propios de Camino, que se quedaban sin plantilla.

**Solución:** mover *Theme: Camino* al **final** de *Sets for this Site* → **Flush all caches**.

> El mismo log muestra `Locale "en_US.UTF-8" ... not found`: es solo un aviso (el contenedor no tiene instalados los idiomas del sistema) y no rompe la página.

`I3-E3-oops-proyectos.png` · `I3-C02-sitio-camino.png`


### Error 4 — La página "proyectos" no salía en el menú

**Causa:** se creó como **Folder** (carpeta), no como página. Una carpeta no tiene página pública.

**Solución:** Edit page properties → **Type: Standard Page** y título `Proyectos`. También se corrigió el título de una página que se había escrito como ruta (`proyectos/coffee-moon` → `Coffee Moon`), recalculando el **URL Segment**.

`I3-E4-carpeta.png`

### Error 5 — El Editor entraba y no veía ninguna página

**Qué pasó:** el árbol del Editor mostraba solo la raíz "Estudio Pixel Verde", vacía.

**Solución:** revisar en el grupo Editor que **Page Tree Entry Points** tuviera **Home**, y que en **Record Permissions** la tabla **Page** estuviera en Read & Write. Después, cerrar sesión del Editor y volver a entrar (TYPO3 lee los permisos del grupo al iniciar sesión).

`I3-E5-editor-vacio.png` · `I3-E5-page-sin-permiso.png`

### Error 6 — Los permisos de página solo se aplicaron a Home

**Qué pasó:** en **Administration → Permissions**, las subpáginas seguían con el grupo `[not set]`.

**Solución:** volver a editar Home con **Depth: Set recursively 2 levels**, para que el cambio bajara a las 7 subpáginas.

`I3-E6-permisos-solo-home.png`

### Error 7 — El Editor no podía abrir un elemento de contenido

**Qué pasó:**

```
Sorry, you didn't have proper permissions to perform this change.
ERROR: authMode "explicitAllow" failed for field "CType" with value "textpic" evaluated
```

**Causa:** `CType` es el tipo de elemento de contenido y `textpic` es **Text & Images**. El grupo Editor solo puede editar los tipos marcados como permitidos, y ese no estaba.

**Solución:** grupo Editor → **Record Permissions** → **Specific Permissions** → *Page Content: Type* → marcar todos los tipos usados en el sitio → guardar → cerrar sesión del Editor y volver a entrar.

**Aprendizaje:** los permisos de TYPO3 son finos: no solo controlan qué páginas y módulos ve un grupo, sino qué **tipo** de contenido puede tocar.

---

## 7. Lista de capturas

### Pasos

| # | Archivo | Qué muestra |
|---|---|---|
| C1 | `I3-C01-media.png` | Carpetas de los proyectos en `fileadmin/proyectos` |
| C1b | `I3-C01b-terminal-fileadmin.png` | Logo y carpetas dentro del contenedor, desde el servidor |
| C2 | `I3-C02-sitio-camino.png` | Sitio `main` con *Theme: Camino* en los sets |
| C2b | `I3-C02b-sitio-main.png` | Sitio `main`: raíz Home y dominio |
| C3 | `I3-C03-colores.png` | Esquema de color Forest Mist en el sitio `main` |
| C4 | `I3-C04-logo.png` | Logo en Home → Appearance |
| C4b | `I3-C04b-logo-publico.png` | Sitio público con el tema y el logo, antes del contenido |
| C5 | `I3-C05-arbol.png` | Árbol de páginas completo, visto por el Editor |
| C6 | `I3-C06-portada.png` | Portada por `https://pixelverde.internal` |
| C6b | `I3-C06b-portada-destacados.png` | Portada: sección Proyectos destacados |
| C7b | `I3-C07b-teaser-grid.png` | Text-Media Teaser Grid en la página Proyectos |
| C7c | `I3-C07c-teaser-item.png` | Ítem del Teaser Grid con imagen y enlace |
| C8 | `I3-C08-un-proyecto.png` | Un proyecto con descripción, "Qué hicimos" e imagen |
| C9a | `I3-C09a-record-permissions.png` | Grupo Editor: Record Permissions (1) |
| C9a-2 | `I3-C09a-record-permissions-2.png` | Grupo Editor: Record Permissions (2) |
| C10 | `I3-C10-mounts.png` | Grupo: Page Tree Entry Points en Home |
| C10b | `I3-C10b-editor-media.png` | El Editor solo ve "Imagenes de proyectos" en Media |
| C11a | `I3-C11a-grupos.png` | Los dos grupos: Administrador y EDITOR DE CONTENIDO |
| C11b | `I3-C11b-crear-editor.png` | Creación de `editor.pixel` con Admin apagado |
| C11c | `I3-C11c-crear-admin.png` | Creación de `diana.admin` con Admin encendido |
| C11d | `I3-C11d-admin-mounts.png` | `diana.admin`: Mount from groups |
| C12 | `I3-C12-permisos-paginas.png` | Permisos de página con el grupo Editor en todas |
| C13 | `I3-C13-menu-admin.png` | Menú del Administrador (comparar con C5, el del Editor) |
| C14a | `I3-C14a-editor-contenido.png` | El Editor ve el Teaser Grid de Proyectos |
| C14b | `I3-C14b-editor-textpic.png` | El Editor ve un Text & Images |
| C15 | `I3-C15-editor-denegado.png` | El Editor recibe "No module access" en Extensions |

### Errores

| Error | Archivo | Qué muestra |
|---|---|---|
| 1 | `I3-E1-home-borrado.png` | Solo queda la página demo Camino |
| 1 | `I3-E1-home-restaurado.png` | Home restaurada como raíz |
| 2 | `I3-E2-logo-en-demo.png` | Logo puesto en la página demo |
| 2 | `I3-E2-sitio-demo.png` | Sitio `camino` (demo) con el tema |
| 2 | `I3-E2-colores-demo.png` | Forest Mist en el sitio demo |
| 2 | `I3-E2-sin-logo-ni-layouts.png` | Home sin campo Logo ni Backend Layouts |
| 3 | `I3-E3-oops-proyectos.png` | "Oops, an error occurred!" en Proyectos |
| 4 | `I3-E4-carpeta.png` | `proyectos` como carpeta y título escrito como ruta |
| 5 | `I3-E5-editor-vacio.png` | El Editor no ve ninguna página |
| 5 | `I3-E5-page-sin-permiso.png` | Tabla Page en No Access |
| 6 | `I3-E6-permisos-solo-home.png` | Grupo Editor solo en Home, subpáginas `[not set]` |
