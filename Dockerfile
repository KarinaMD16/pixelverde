# =============================================================================
#  Imagen de TYPO3 para el Estudio Pixel Verde
#
#  - Base oficial de PHP con Apache (PHP 8.4: TYPO3 14 LTS acepta 8.2 a 8.5)
#  - TYPO3 14.3.9 LTS en "modo clásico" (paquete .tar.gz oficial, sin Composer)
#  - El paquete se verifica con su SHA256 publicado en get.typo3.org
#
#  Si se cambia la versión de TYPO3, hay que cambiar TYPO3_VERSION y
#  TYPO3_SHA256 juntos (el SHA256 está en https://get.typo3.org/version/14).
# =============================================================================
FROM php:8.4-apache

ARG TYPO3_VERSION=14.3.9
ARG TYPO3_SHA256=4e06a884a8ec04ecb1b371cb06f7eae256c9740ff25c0a93bc13786d3ef6a7ee

# 1) Paquetes del sistema:
#    - librerías para compilar las extensiones de PHP
#    - graphicsmagick: TYPO3 lo usa para recortar y escalar imágenes
#    - gosu: para correr "typo3 setup" como www-data conservando las variables
#    - mariadb-client: deja usar mariadb-dump/mariadb desde este contenedor si hace falta
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libfreetype6-dev libjpeg62-turbo-dev libpng-dev libwebp-dev \
      libicu-dev libzip-dev \
      graphicsmagick gosu mariadb-client curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# 2) Extensiones de PHP que pide TYPO3 y que no vienen ya en la imagen base
#    (pdo, xml, mbstring, tokenizer, session, filter y sodium ya vienen incluidas)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
 && docker-php-ext-install -j"$(nproc)" gd intl mysqli pdo_mysql zip opcache exif

# 3) Configuración de PHP recomendada por TYPO3
COPY config/php.ini /usr/local/etc/php/conf.d/typo3.ini

# 4) Apache: módulos que pide TYPO3 y permiso para usar su .htaccess
RUN a2enmod rewrite headers expires deflate setenvif
COPY config/apache-typo3.conf /etc/apache2/conf-available/typo3.conf
RUN a2enconf typo3

# 5) Descargar TYPO3, verificar el SHA256 y armar los enlaces del modo clásico:
#       /var/www/typo3_src-14.3.9/          <- código de TYPO3 (no se toca)
#       /var/www/html/typo3_src  -> ../typo3_src-14.3.9
#       /var/www/html/typo3      -> typo3_src/typo3
#       /var/www/html/index.php  -> typo3_src/index.php
#    y copiar el .htaccess oficial de TYPO3 (URLs amigables y la ruta /typo3/ del
#    backend dependen de él). Va en la imagen para que nunca se pierda al recrear
#    el contenedor, porque /var/www/html no es un volumen.
RUN curl -fsSL -o /tmp/typo3_src.tgz "https://get.typo3.org/${TYPO3_VERSION}/tar.gz" \
 && echo "${TYPO3_SHA256}  /tmp/typo3_src.tgz" | sha256sum -c - \
 && tar -xzf /tmp/typo3_src.tgz -C /var/www/ \
 && rm /tmp/typo3_src.tgz \
 && cd /var/www/html \
 && ln -s ../typo3_src-${TYPO3_VERSION} typo3_src \
 && ln -s typo3_src/typo3 typo3 \
 && ln -s typo3_src/index.php index.php \
 && cp typo3_src/typo3/sysext/install/Resources/Private/FolderStructureTemplateFiles/root-htaccess .htaccess \
 && mkdir -p fileadmin typo3conf/system typo3temp \
 && chown -R www-data:www-data /var/www/html

# 6) Script de arranque (instala TYPO3 la primera vez) y configuración de proxy
COPY config/additional.php /usr/local/share/typo3/additional.php
COPY docker/entrypoint.sh /usr/local/bin/pixelverde-entrypoint
RUN chmod +x /usr/local/bin/pixelverde-entrypoint

WORKDIR /var/www/html
EXPOSE 80

ENTRYPOINT ["pixelverde-entrypoint"]
CMD ["apache2-foreground"]
