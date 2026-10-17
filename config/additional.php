<?php
/*
 * Configuración extra de TYPO3 para Pixel Verde.
 *
 * Este archivo lo copia el contenedor a typo3conf/system/additional.php en
 * cada arranque. NO se edita dentro del contenedor: los valores se cambian
 * en el archivo .env y se aplican con "docker compose up -d".
 *
 * Lo usa sobre todo el Integrante 2 (dominio + HTTPS con proxy inverso).
 */

// 1) Dominios desde los que TYPO3 acepta peticiones (expresión regular, sin ^ ni $).
//    Si llega un dominio que no coincide, TYPO3 responde "trusted host" error.
$trustedHosts = getenv('TYPO3_TRUSTED_HOSTS');
if ($trustedHosts !== false && $trustedHosts !== '') {
    $GLOBALS['TYPO3_CONF_VARS']['SYS']['trustedHostsPattern'] = $trustedHosts;
}

// 2) Proxy inverso: el Apache del servidor reenvía las peticiones al contenedor.
//    Dentro de Docker, esas peticiones llegan desde la puerta de enlace de la red
//    "pixelverde_interna" (172.30.0.1). Así TYPO3 usa la IP real del visitante.
$proxyIp = getenv('TYPO3_REVERSE_PROXY_IP');
if ($proxyIp !== false && $proxyIp !== '') {
    $GLOBALS['TYPO3_CONF_VARS']['SYS']['reverseProxyIP'] = $proxyIp;
    $GLOBALS['TYPO3_CONF_VARS']['SYS']['reverseProxyHeaderMultiValue'] = 'first';
}

// 3) HTTPS en el proxy: cuando Apache ya atiende https://pixelverde.internal,
//    se pone TYPO3_REVERSE_PROXY_SSL=172.30.0.1 en el .env para que TYPO3 genere
//    los enlaces con https:// (si no, los estilos y el backend pueden quedar rotos).
//    Mientras se prueba directo por http://localhost:8080, se deja vacío.
$proxySsl = getenv('TYPO3_REVERSE_PROXY_SSL');
if ($proxySsl !== false && $proxySsl !== '') {
    $GLOBALS['TYPO3_CONF_VARS']['SYS']['reverseProxySSL'] = $proxySsl;
}
