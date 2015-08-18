#!/bin/bash
set -e

echo "Executing $BASH_SOURCE"

if [ ${ENTRYPOINT_INITIALIZED}=false ]; then

	# setup ssl certificate and key
	if [ -n "${CONF_APACHE2_SSL_CERT}" ]; then
		echo "${CONF_APACHE2_SSL_CERT}" >${SSL_DIR}/apache2.pem
	else
		# fallback to snakeoil cert
		cat /etc/ssl/certs/ssl-cert-snakeoil.pem >${SSL_DIR}/apache2.pem
	fi
	if [ -n "${CONF_APACHE2_SSL_KEY}" ]; then
		echo "${CONF_APACHE2_SSL_KEY}" >${SSL_DIR}/apache2.key
	else
		# fallback to snakeoil key
		cat /etc/ssl/private/ssl-cert-snakeoil.key >${SSL_DIR}/apache2.key
	fi

	# empty out default index site
	echo "" >/var/www/index.html

	# default-ssl
	a2enmod ssl
	a2ensite default-ssl
	
	# set ssl certificates
	setConfigValue /etc/apache2/sites-available/default-ssl SSLCertificateFile "${SSL_DIR}/apache2.pem"
	setConfigValue /etc/apache2/sites-available/default-ssl SSLCertificateKeyFile "${SSL_DIR}/apache2.key"

	# disable unsecure
	a2dissite default
	sed -i /etc/apache2/ports.conf \
		-e 's/^\([ \t]*NameVirtualHost[ \t]*\*:80\)/#\1/' \
		-e 's/^\([ \t]*Listen[ \t]*80\)/#\1/'


fi

